import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pet_repository.dart';
import '../domain/pet.dart';

/// main()에서 override 주입.
final petRepositoryProvider = Provider<PetRepository>(
  (ref) => throw UnimplementedError('petRepositoryProvider must be overridden'),
);

/// 저장된 펫 (없으면 null = 아직 온보딩 안 함).
class PetController extends Notifier<Pet?> {
  @override
  Pet? build() => ref.read(petRepositoryProvider).load();

  Future<void> save(Pet pet) async {
    await ref.read(petRepositoryProvider).save(pet);
    state = pet;
  }

  Future<void> addPoints(int amount) async {
    final p = state;
    if (p == null) return;
    await save(p.copyWith(points: p.points + amount));
  }

  /// 밥주기: 배고픔(포만도) 회복 + 약간의 포인트.
  Future<void> feed() async {
    final p = state;
    if (p == null) return;
    await save(p.copyWith(hunger: p.hunger + 20, points: p.points + 5));
  }

  /// 놀아주기: 행복도 상승, 피로도 약간 증가.
  Future<void> play() async {
    final p = state;
    if (p == null) return;
    await save(p.copyWith(
        happiness: p.happiness + 20, fatigue: p.fatigue + 10, points: p.points + 5));
  }

  /// 잠자기: 피로도 회복.
  Future<void> sleep() async {
    final p = state;
    if (p == null) return;
    await save(p.copyWith(fatigue: p.fatigue - 30));
  }

  /// 아이템 장착/해제 토글.
  Future<void> toggleItem(String id) async {
    final p = state;
    if (p == null) return;
    final list = [...p.equippedItems];
    list.contains(id) ? list.remove(id) : list.add(id);
    await save(p.copyWith(equippedItems: list));
  }

  Future<void> reset() async {
    await ref.read(petRepositoryProvider).clear();
    state = null;
  }
}

final petProvider = NotifierProvider<PetController, Pet?>(PetController.new);

/// 온보딩 진행 중 단계별로 채워지는 초안.
class OnboardingController extends Notifier<PetDraft> {
  bool isGuest = false;

  @override
  PetDraft build() => PetDraft(furColorValue: null);

  void update(void Function(PetDraft d) mutate) {
    final next = state.copy();
    mutate(next);
    state = next;
  }

  Future<Pet> complete() async {
    final pet = state.finalize();
    await ref.read(petProvider.notifier).save(pet);
    return pet;
  }

  void restart() {
    state = PetDraft(furColorValue: null);
    isGuest = false;
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingController, PetDraft>(OnboardingController.new);
