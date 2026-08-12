import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/nickname_service.dart' show firestoreProvider;
import '../domain/community_models.dart';

/// 가입자 명부와 이웃 관계.
///
/// 앱에는 로그인 화면이 없지만 익명 로그인으로 기기마다 uid 가 하나 생긴다.
/// 그 uid 를 문서 ID 로 삼아 프로필을 두고, 이웃은 그 아래 하위 컬렉션에 넣는다.
/// 덕분에 보안 규칙이 "본인 것만 쓰기"를 직접 검증할 수 있다.
///
/// ```
/// users/{uid}                      프로필(닉네임·펫이름·아바타·가입시각)
/// users/{uid}/neighbors/{otherUid} 내가 추가한 이웃
/// ```
class UserDirectory {
  UserDirectory(this._db);

  final FirebaseFirestore? _db;

  static const _col = 'users';

  String? get myUid => FirebaseAuth.instance.currentUser?.uid;
  bool get available => _db != null && myUid != null;

  CollectionReference<Map<String, dynamic>>? get _users =>
      _db?.collection(_col);

  /// 온보딩을 마칠 때 내 프로필을 명부에 올린다.
  /// 이미 있으면 닉네임·펫 정보만 갱신하고 가입 시각은 그대로 둔다.
  Future<void> upsertMe({
    required String nickname,
    required String petName,
    String emoji = '🐾',
    int avatarColor = 0xFFFFE0B2,
    String? avatarUrl,
  }) async {
    final uid = myUid;
    final users = _users;
    if (uid == null || users == null) return;
    final doc = users.doc(uid);
    final snap = await doc.get();
    await doc.set({
      'nickname': nickname,
      'petName': petName,
      'emoji': emoji,
      'avatarColor': avatarColor,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      // 가입 시각은 처음 한 번만 찍는다(최근 가입 정렬 기준).
      if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 프로필 사진만 갱신.
  Future<void> updateAvatar(String url) async {
    final uid = myUid;
    final users = _users;
    if (uid == null || users == null) return;
    await users.doc(uid).set({'avatarUrl': url}, SetOptions(merge: true));
  }

  /// 최근 가입한 사람들(나 제외). 이웃 목록의 "추천" 자리에 쓴다.
  Stream<List<Neighbor>> watchRecent({int limit = 10}) {
    final users = _users;
    if (users == null) return Stream.value(const []);
    return users
        .orderBy('createdAt', descending: true)
        .limit(limit + 1) // 내가 섞여 있을 수 있으니 하나 더 받는다
        .snapshots()
        .map((s) => s.docs
            .where((d) => d.id != myUid)
            .take(limit)
            .map(_fromDoc)
            .toList());
  }

  /// 내가 추가한 이웃들.
  Stream<List<Neighbor>> watchMyNeighbors() {
    final uid = myUid;
    final users = _users;
    if (uid == null || users == null) return Stream.value(const []);
    return users
        .doc(uid)
        .collection('neighbors')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  /// 이웃 추가/삭제. 상대 프로필을 복사해 두어 목록을 바로 그릴 수 있게 한다.
  Future<void> addNeighbor(Neighbor n) async {
    final uid = myUid;
    final users = _users;
    if (uid == null || users == null) throw StateError('네트워크가 필요해요');
    await users.doc(uid).collection('neighbors').doc(n.id).set({
      'nickname': n.owner,
      'petName': n.petName,
      'emoji': n.emoji,
      'avatarColor': n.avatarColor.toARGB32(),
      'avatarUrl': n.avatarUrl,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeNeighbor(String otherUid) async {
    final uid = myUid;
    final users = _users;
    if (uid == null || users == null) throw StateError('네트워크가 필요해요');
    await users.doc(uid).collection('neighbors').doc(otherUid).delete();
  }

  /// 닉네임으로 찾기(정확히 일치). 명부에는 닉네임이 하나뿐이라 한 명만 나온다.
  Future<List<Neighbor>> searchByNickname(String q) async {
    final users = _users;
    if (users == null || q.trim().isEmpty) return const [];
    final snap =
        await users.where('nickname', isEqualTo: q.trim()).limit(10).get();
    return snap.docs.where((d) => d.id != myUid).map(_fromDoc).toList();
  }

  static Neighbor _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    final nick = (m['nickname'] as String?) ?? '이웃';
    return Neighbor(
      id: d.id, // 상대 uid
      owner: nick,
      petName: (m['petName'] as String?) ?? '',
      breed: '',
      emoji: (m['emoji'] as String?) ?? '🐾',
      avatarColor: Color((m['avatarColor'] as num?)?.toInt() ?? 0xFFFFE0B2),
      location: '',
      avatarUrl: m['avatarUrl'] as String?,
    );
  }
}

final userDirectoryProvider = Provider<UserDirectory>(
  (ref) => UserDirectory(ref.watch(firestoreProvider)),
);

/// 최근 가입 10명(나 제외).
final recentUsersProvider = StreamProvider<List<Neighbor>>(
  (ref) => ref.watch(userDirectoryProvider).watchRecent(),
);

/// 내가 추가한 이웃.
final myNeighborsProvider = StreamProvider<List<Neighbor>>(
  (ref) => ref.watch(userDirectoryProvider).watchMyNeighbors(),
);
