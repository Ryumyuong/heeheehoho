import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 주인(사람) 닉네임의 중복 검사·예약을 담당한다.
///
/// **강아지 이름은 여기 오지 않는다** — 같은 이름의 강아지는 흔하므로 중복을
/// 허용한다. 커뮤니티에서 나를 가리키는 주인 닉네임만 겹치면 안 된다.
///
/// Firestore `owner_nicknames` 컬렉션에 소문자로 정규화한 이름을 문서 ID로
/// 저장한다. 문서가 있으면 이미 사용 중, 없으면 사용 가능.
///
/// 예전 버전은 **강아지 이름**을 `nicknames` 컬렉션에 예약했다. 그쪽에는 이미
/// 출시본 사용자들의 강아지 이름이 쌓여 있어서, 그대로 쓰면 "뭉치" 같은 흔한
/// 강아지 이름을 사람 닉네임으로 못 쓰게 된다. 그래서 컬렉션을 분리했다.
/// (옛 `nicknames`는 이제 아무도 읽지 않으므로 콘솔에서 지워도 된다.)
///
/// Firebase 초기화가 안 됐거나 네트워크가 없으면 [available]이 false가 되고,
/// 그때는 중복 검사를 건너뛴다(온보딩이 막히지 않게).
class NicknameService {
  NicknameService(this._db);

  final FirebaseFirestore? _db;

  static const _collection = 'owner_nicknames';

  bool get available => _db != null;

  /// 대소문자·앞뒤 공백 차이를 무시하도록 정규화한 키.
  static String keyOf(String name) => name.trim().toLowerCase();

  /// 형식 검사: 1~8자, 공백/특수문자 없음(한글·영문·숫자만).
  /// 문제 없으면 null, 있으면 사용자에게 보여줄 사유를 돌려준다.
  static String? formatError(String name) {
    final n = name.trim();
    if (n.isEmpty) return null; // 빈 값은 오류로 안 띄운다(입력 전)
    // 한글·영문·숫자는 1글자=1코드유닛이라 length로 충분(이모지는 아래 정규식이 막음).
    if (n.length > 8) return '이름은 8자 이내로 지어주세요';
    if (!RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(n)) {
      return '한글·영문·숫자만 쓸 수 있어요';
    }
    return null;
  }

  /// 이미 사용 중인지. 사용 중이면 true. 검사 불가 환경이면 false(통과).
  Future<bool> isTaken(String name) async {
    final db = _db;
    if (db == null) return false;
    final doc = await db.collection(_collection).doc(keyOf(name)).get();
    return doc.exists;
  }

  /// 이름을 예약(등록)한다. 온보딩 완료 시 호출. 실패해도 앱은 진행한다.
  Future<void> reserve(String name) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection(_collection).doc(keyOf(name)).set({
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 네트워크 오류 등은 조용히 넘어간다(중복은 다음 검사에서 다시 걸린다).
    }
  }
}

/// main()에서 Firebase 초기화 성공 시 Firestore 인스턴스를 주입한다.
/// 초기화 안 됐으면 null → 서비스가 검사를 건너뛴다.
final firestoreProvider = Provider<FirebaseFirestore?>((ref) => null);

final nicknameServiceProvider = Provider<NicknameService>(
  (ref) => NicknameService(ref.watch(firestoreProvider)),
);
