import 'package:flutter/widgets.dart' show Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/room_item.dart';
import '../data/pet_repository.dart';
import '../domain/pet.dart';

/// main()에서 override 주입.
final petRepositoryProvider = Provider<PetRepository>(
  (ref) => throw UnimplementedError('petRepositoryProvider must be overridden'),
);

/// 저장된 펫 (없으면 null = 아직 온보딩 안 함).
class PetController extends Notifier<Pet?> {
  @override
  Pet? build() {
    return ref.read(petRepositoryProvider).load();
  }

  Future<void> save(Pet pet) async {
    await ref.read(petRepositoryProvider).save(pet);
    state = pet;
  }

  Future<void> addPaws(int amount) async {
    final p = state;
    if (p == null) return;
    await save(p.copyWith(paws: p.paws + amount));
  }

  /// 밥주기: 배고픔(포만도) 회복 + 약간의 발자국.
  Future<void> feed() async {
    final p = state;
    if (p == null) return;
    await save(p.copyWith(hunger: p.hunger + 20, paws: p.paws + 5));
  }

  /// 놀아주기: 행복도 상승, 피로도 약간 증가.
  Future<void> play() async {
    final p = state;
    if (p == null) return;
    await save(
      p.copyWith(
        happiness: p.happiness + 20,
        fatigue: p.fatigue + 10,
        paws: p.paws + 5,
      ),
    );
  }

  /// 잠자기: 피로도 회복.
  Future<void> sleep() async {
    final p = state;
    if (p == null) return;
    await save(p.copyWith(fatigue: p.fatigue - 30));
  }

  /// 미니룸 아이템 구매: 발자국 차감 + 보유 목록에 추가(한 번에 저장).
  /// 발자국이 충분한지는 호출부에서 확인한다.
  Future<void> purchaseItems(Iterable<String> ids, int cost) async {
    final p = state;
    if (p == null) return;
    final owned = {...p.ownedItems, ...ids}.toList();
    await save(p.copyWith(paws: p.paws - cost, ownedItems: owned));
  }

  /// 마켓 구매하기: 뼈다귀 차감. 뼈다귀가 충분한지는 호출부에서 확인한다.
  Future<void> spendBones(int cost) async {
    final p = state;
    if (p == null) return;
    await save(p.copyWith(bones: p.bones - cost));
  }

  /// 아이템 장착/해제 토글. 머리 아이템은 같은 슬롯의 다른 아이템을 자동 해제.
  Future<void> toggleItem(String id) async {
    final p = state;
    if (p == null) return;
    final list = [...p.equippedItems];
    if (list.contains(id)) {
      list.remove(id);
    } else {
      if (kHeadSlotItems.contains(id)) {
        list.removeWhere(kHeadSlotItems.contains);
      }
      list.add(id);
    }
    await save(p.copyWith(equippedItems: list));
  }

  /// 가구를 정규화 좌표(0~1)와 크기 배율로 배치(또는 이동) 후 고정.
  Future<void> placeFurniture(
    String id,
    Offset normPos, [
    double scale = 1.0,
  ]) async {
    final p = state;
    if (p == null) return;
    final eq = [...p.equippedItems];
    if (!eq.contains(id)) eq.add(id);
    final pl = {...p.placements}..[id] = normPos;
    final sc = {...p.placementScales}..[id] = scale;
    await save(
      p.copyWith(equippedItems: eq, placements: pl, placementScales: sc),
    );
  }

  /// 배치된 가구 제거.
  Future<void> removeFurniture(String id) async {
    final p = state;
    if (p == null) return;
    final eq = [...p.equippedItems]..remove(id);
    final pl = {...p.placements}..remove(id);
    final sc = {...p.placementScales}..remove(id);
    await save(
      p.copyWith(equippedItems: eq, placements: pl, placementScales: sc),
    );
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

final onboardingProvider = NotifierProvider<OnboardingController, PetDraft>(
  OnboardingController.new,
);

/// 현재 세션이 비회원인지 여부 (영속). 아이템 구매 등 로그인 필요 동작의 가드에 사용.
class SessionController extends Notifier<bool> {
  @override
  bool build() => ref.read(petRepositoryProvider).loadIsGuest();

  Future<void> setGuest(bool value) async {
    await ref.read(petRepositoryProvider).saveIsGuest(value);
    state = value;
  }
}

final isGuestProvider = NotifierProvider<SessionController, bool>(
  SessionController.new,
);
