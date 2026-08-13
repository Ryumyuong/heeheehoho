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
  /// 시간당 상태값 변화량. 돌보지 않고 두면 애정도·포만감이 떨어지고
  /// 피로도가 쌓인다. 하루(24시간) 기준으로 대략 -36 / -48 / +24 다.
  static const _happinessPerHour = -1.5;
  static const _hungerPerHour = -2.0;
  static const _fatiguePerHour = 1.0;

  @override
  Pet? build() {
    final pet = ref.read(petRepositoryProvider).load();
    if (pet == null) return null;
    // 앱을 껐던 동안 흐른 시간도 반영해서 시작한다.
    return _decayed(pet, DateTime.now());
  }

  /// [now]까지 흐른 시간만큼 상태값을 밀어 놓은 사본.
  /// 저장하지는 않는다 — 화면에 보일 값만 계산한다([applyDecay]가 저장한다).
  static Pet _decayed(Pet p, DateTime now) {
    final since = p.statsAt;
    if (since == null) return p.copyWith(statsAt: now);
    final hours = now.difference(since).inMinutes / 60.0;
    // 시계가 뒤로 간 경우(시간대 변경 등)는 건너뛴다.
    if (hours <= 0) return p;
    return p.copyWith(
      happiness: (p.happiness + _happinessPerHour * hours).round(),
      hunger: (p.hunger + _hungerPerHour * hours).round(),
      fatigue: (p.fatigue + _fatiguePerHour * hours).round(),
      statsAt: now,
    );
  }

  /// 흐른 시간만큼 상태값을 갱신해 저장한다.
  /// 앱을 켤 때와 다시 앞으로 돌아올 때 홈 화면이 부른다.
  Future<void> applyDecay() async {
    final p = state;
    if (p == null) return;
    final next = _decayed(p, DateTime.now());
    // 1분 미만이면 변화가 없어 저장할 이유가 없다.
    if (next.happiness == p.happiness &&
        next.hunger == p.hunger &&
        next.fatigue == p.fatigue) {
      return;
    }
    await save(next);
  }

  /// 산책을 마쳤을 때: 같이 걸었으니 애정도가 오르고, 그만큼 지치고 배가 준다.
  /// 걸음 수에 비례하되 한 번에 너무 크게 흔들리지 않도록 상한을 둔다.
  Future<void> applyWalkEffect(int steps) async {
    final p = state;
    if (p == null || steps <= 0) return;
    // 1,000걸음당 애정도 +5 / 피로도 +4 / 포만감 -3, 각각 최대 25·20·15.
    final k = steps / 1000.0;
    await save(p.copyWith(
      happiness: p.happiness + (k * 5).round().clamp(1, 25),
      fatigue: p.fatigue + (k * 4).round().clamp(1, 20),
      hunger: p.hunger - (k * 3).round().clamp(1, 15),
      statsAt: DateTime.now(),
    ));
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
