import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../onboarding/data/nickname_service.dart' show firestoreProvider;

/// 밸런스 게임 투표를 Firestore로 실시간 집계한다.
///
/// - 문서: `community/balance_{gameId}` 에 `votesA`, `votesB`(정수) 저장.
/// - 첫 투표 때 시안 기준값(seed)으로 문서를 만들고, 이후엔 증감만 한다.
/// - 내 선택은 로컬(Hive)에 저장해 재접속 시에도 유지하고, 중복 증가를 막는다.
///
/// Firebase 초기화 실패 시(_db == null) [available]이 false가 되고,
/// 화면은 로컬 계산으로 폴백한다.
class BalanceVoteService {
  BalanceVoteService(this._db);

  final FirebaseFirestore? _db;

  bool get available => _db != null;

  DocumentReference<Map<String, dynamic>>? _doc(String gameId) =>
      _db?.collection('community').doc('balance_$gameId');

  /// 실시간 표 수 스트림. Firestore가 없으면 null.
  Stream<({int votesA, int votesB})>? watch(String gameId) {
    final d = _doc(gameId);
    if (d == null) return null;
    return d.snapshots().map((snap) {
      final m = snap.data();
      return (
        votesA: (m?['votesA'] as num?)?.toInt() ?? 0,
        votesB: (m?['votesB'] as num?)?.toInt() ?? 0,
      );
    });
  }

  /// 투표(또는 선택 변경). [previous]가 있으면 그 쪽을 1 빼고 [choice] 쪽을 1 더한다.
  /// 문서가 없으면 [seedA]/[seedB]로 만든 뒤 반영한다.
  Future<void> vote(
    String gameId, {
    required int choice, // 0=A, 1=B
    int? previous,
    required int seedA,
    required int seedB,
  }) async {
    final d = _doc(gameId);
    final db = _db;
    if (d == null || db == null) return;
    if (previous == choice) return; // 같은 쪽 재선택은 무시
    try {
      await db.runTransaction((tx) async {
        final snap = await tx.get(d);
        int a, b;
        if (!snap.exists) {
          a = seedA;
          b = seedB;
        } else {
          final m = snap.data()!;
          a = (m['votesA'] as num?)?.toInt() ?? seedA;
          b = (m['votesB'] as num?)?.toInt() ?? seedB;
        }
        if (previous == 0 && a > 0) a -= 1;
        if (previous == 1 && b > 0) b -= 1;
        if (choice == 0) {
          a += 1;
        } else {
          b += 1;
        }
        tx.set(d, {'votesA': a, 'votesB': b}, SetOptions(merge: true));
      });
    } catch (_) {
      // 네트워크/권한 오류는 조용히 넘어간다(다음 시도에서 다시 반영).
    }
  }

  // ── 내 선택(로컬) ──────────────────────────────────────────────
  static const _boxName = 'community_box';

  Future<Box> _box() async => Hive.isBoxOpen(_boxName)
      ? Hive.box(_boxName)
      : await Hive.openBox(_boxName);

  Future<int?> loadMyChoice(String gameId) async {
    try {
      final v = (await _box()).get('vote_$gameId');
      return v is int ? v : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMyChoice(String gameId, int choice) async {
    try {
      await (await _box()).put('vote_$gameId', choice);
    } catch (_) {}
  }
}

final balanceVoteServiceProvider = Provider<BalanceVoteService>(
  (ref) => BalanceVoteService(ref.watch(firestoreProvider)),
);
