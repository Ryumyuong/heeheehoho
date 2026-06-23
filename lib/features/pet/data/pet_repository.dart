import 'package:hive_flutter/hive_flutter.dart';
import '../domain/pet.dart';

/// Hive 박스에 펫 상태를 Map 형태로 영속화한다. (코드 생성 불필요)
class PetRepository {
  PetRepository(this._box);

  final Box _box;
  static const _key = 'pet';

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
}
