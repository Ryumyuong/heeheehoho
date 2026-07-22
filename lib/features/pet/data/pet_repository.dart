import 'package:hive_flutter/hive_flutter.dart';
import '../domain/pet.dart';

/// Hive 박스에 펫 상태를 Map 형태로 영속화한다. (코드 생성 불필요)
class PetRepository {
  PetRepository(this._box);

  final Box _box;
  static const _key = 'pet';
  static const _guestKey = 'is_guest';

  static Future<PetRepository> open() async {
    final box = await Hive.openBox('pet_box');
    return PetRepository(box);
  }

  Pet? load() {
    final raw = _box.get(_key);
    if (raw is Map) return Pet.fromMap(raw);
    return null;
  }

  Future<void> save(Pet pet) async {
    await _box.put(_key, pet.toMap());
  }

  Future<void> clear() async => _box.delete(_key);

  /// 현재 세션이 비회원인지. (구매 등 로그인 필요 동작의 가드에 사용)
  bool loadIsGuest() => _box.get(_guestKey, defaultValue: false) as bool;

  Future<void> saveIsGuest(bool value) async => _box.put(_guestKey, value);
}
