import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/pixel_theme.dart';
import '../../home/domain/room_item.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/domain/dog_appearance.dart';
import '../../pet/presentation/widgets/dog_with_wearables.dart';
import '../application/campaign_providers.dart';
import '../domain/market_item.dart';
import '../../../shared/widgets/design_scale.dart';
import '../../../shared/widgets/wallet_chip.dart';

/// 스토어 화면 좌우 여백. 시안(412px)에서 28px이고, 폭이 달라지면 함께 늘고 준다.
double _hPad(BuildContext context) => DesignScale.scaled(context, 28);

/// 스토어: 미니룸(아이템 구매) / 마켓 탭.
class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key});

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

enum _StoreCat { all, interior, costume, trick }

extension _StoreCatLabel on _StoreCat {
  String get label => switch (this) {
    _StoreCat.all => '전체',
    _StoreCat.interior => '인테리어',
    _StoreCat.costume => '코스튬',
    _StoreCat.trick => '개인기',
  };

  String? get icon => switch (this) {
    _StoreCat.all => null,
    _StoreCat.interior => 'assets/icons/cat_interior.png',
    _StoreCat.costume => 'assets/icons/cat_costume.png',
    _StoreCat.trick => 'assets/icons/cat_trick.png',
  };

  bool matches(RoomItem item) => switch (this) {
    _StoreCat.all => true,
    _StoreCat.interior => item.category == ItemCategory.furniture,
    _StoreCat.costume => item.category == ItemCategory.wearable,
    _StoreCat.trick => false, // 개인기 아이템 준비 중
  };
}

class _StorePageState extends ConsumerState<StorePage> {
  int _tab = 0; // 0 미니룸, 1 마켓
  _StoreCat _cat = _StoreCat.all;
  final Set<String> _cart = {};
  final ScrollController _scroll = ScrollController();

  // 방 미리보기 배치 상태: 확정된 여러 개(_placed*) + 현재 옮기는 중(_previewItem).
  final Map<String, Offset> _placedPos = {}; // 확정 위치(정규화 0~1)
  final Map<String, double> _placedScale = {}; // 확정 크기 배율
  String? _previewItem; // 지금 옮기는 중인 상품 id (미확정)
  Offset _previewPos = const Offset(0.5, 0.58);
  double _previewScale = 1.0;
  static const double _previewMin = 0.5;
  static const double _previewMax = 4.0;

  // 코스튬(웨어러블) 트라이온 상태: 프리뷰 강아지에 입혀본 아이템 id.
  // 클릭 즉시 구매하지 않고 여기서 미리 착용해 보고, "홈에 저장" 시 실제 반영한다.
  final Set<String> _tryOn = {};

  @override
  void initState() {
    super.initState();
    // 현재 펫이 이미 착용 중인 웨어러블을 트라이온 초기값으로 → 프리뷰가 실제 강아지와 일치.
    final pet = ref.read(petProvider);
    if (pet != null) {
      _tryOn.addAll(
        pet.equippedItems.where(
          (id) => kRoomItems.any(
            (e) => e.id == id && e.category == ItemCategory.wearable,
          ),
        ),
      );
    }
    // 스토어를 처음 여는 순간 이미 탭 요청이 있으면(예: "마켓으로 열어줘")
    // 그 탭으로 시작한다. ref.listen은 변화만 잡으므로 초기값은 여기서 읽는다.
    final req = ref.read(storeTabRequestProvider);
    if (req != null) {
      _tab = req == StoreTab.market ? 1 : 0;
      // 프레임 밖에서 요청을 비운다(초기화 중 provider 수정을 피한다).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(storeTabRequestProvider.notifier).consume();
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// 상품 이미지를 탭 → 방 미리보기에서 옮기기 시작.
  /// 이미 배치된 아이템이면 그 위치·크기로 이어서 편집한다.
  void _pickPreview(RoomItem item) {
    // 코스튬(웨어러블)은 배치 미리보기 대신, 프리뷰 강아지에 바로 입혀본다(트라이온).
    // 구매는 하지 않고 "홈에 저장" 시점에 처리한다.
    if (item.category == ItemCategory.wearable) {
      setState(() {
        if (_tryOn.contains(item.id)) {
          _tryOn.remove(item.id);
        } else {
          // 머리 슬롯(왕관·리본)은 하나만. 홈의 착용 규칙과 동일하게 맞춘다.
          if (kHeadSlotItems.contains(item.id)) {
            _tryOn.removeAll(kHeadSlotItems);
          }
          _tryOn.add(item.id);
        }
      });
      return;
    }
    setState(() {
      _commitActive(); // 옮기던 게 있으면 먼저 확정
      _previewItem = item.id;
      _previewPos = _placedPos.remove(item.id) ?? const Offset(0.5, 0.58);
      _previewScale = _placedScale.remove(item.id) ?? 1.0;
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  /// 편집 중인 아이템을 확정 목록에 넣는다(내부용 — setState 안에서 호출).
  void _commitActive() {
    final id = _previewItem;
    if (id == null) return;
    _placedPos[id] = _previewPos;
    _placedScale[id] = _previewScale;
    _previewItem = null;
  }

  /// ✓ 현재 아이템 확정 → 다음 아이템을 이어서 배치할 수 있다.
  void _confirmPreview() => setState(_commitActive);

  /// ✗ 현재 옮기던 아이템을 미리보기에서 제거(확정 안 함).
  void _cancelPreview() => setState(() => _previewItem = null);

  /// 확정된(편집 중이 아닌) 미리보기 아이템 목록.
  List<({RoomItem item, Offset pos, double scale})> get _placedList {
    final out = <({RoomItem item, Offset pos, double scale})>[];
    _placedPos.forEach((id, pos) {
      final item = kRoomItems.firstWhere(
        (e) => e.id == id,
        orElse: () => kRoomItems.first,
      );
      out.add((item: item, pos: pos, scale: _placedScale[id] ?? 1.0));
    });
    return out;
  }

  bool get _hasPreview =>
      _previewItem != null || _placedPos.isNotEmpty || _tryOn.isNotEmpty;

  /// 미리보기 배치(여러 개) + 트라이온 코스튬을 그대로 홈(방)에 저장.
  /// 미보유 상품은 자동으로 구매(발자국 차감) 후 배치 — 발자국이 부족할 때만 막는다.
  /// 가구는 좌표·크기로 배치, 코스튬은 착용(트라이온 해제분은 벗김).
  Future<void> _saveToHome() async {
    setState(_commitActive); // 옮기던 것도 포함해서 확정
    // 배치할 가구 + 입어본 코스튬을 모두 대상으로.
    final ids = {..._placedPos.keys, ..._tryOn}.toList();
    if (ids.isEmpty) {
      _snack('배치하거나 입어볼 상품을 먼저 골라주세요');
      return;
    }
    final pet = ref.read(petProvider);
    if (pet == null) {
      _snack('아직 네발 친구가 없어요. 온보딩을 먼저 완료해 주세요');
      return;
    }
    final owned = pet.ownedItems.toSet();
    final notifier = ref.read(petProvider.notifier);

    // 미보유 상품은 구매. 필요한 발자국이 모자라면 중단.
    final toBuy = ids.where((id) => !owned.contains(id)).toList();
    final cost = kRoomItems
        .where((e) => toBuy.contains(e.id))
        .fold(0, (s, e) => s + e.price);
    if (cost > pet.paws) {
      _snack('발자국이 부족해요. 충전 페이지로 이동할게요.');
      context.push('/charge');
      return;
    }
    if (toBuy.isNotEmpty) {
      final names = kRoomItems
          .where((e) => toBuy.contains(e.id))
          .map((e) => e.label)
          .join(', ');
      final ok = await _confirmPurchase(names, cost);
      if (ok != true || !mounted) return;
      await notifier.purchaseItems(toBuy, cost);
    }

    final equipped =
        ref.read(petProvider)?.equippedItems.toSet() ?? const <String>{};
    // 코스튬: 프리뷰(_tryOn)와 실제 착용 상태를 동기화한다.
    for (final w in kRoomItems.where(
      (e) => e.category == ItemCategory.wearable,
    )) {
      final want = _tryOn.contains(w.id);
      final has = equipped.contains(w.id);
      if (want != has) await notifier.toggleItem(w.id);
    }
    for (final id in _placedPos.keys) {
      final item = kRoomItems.firstWhere(
        (e) => e.id == id,
        orElse: () => kRoomItems.first,
      );
      if (item.category == ItemCategory.furniture) {
        await notifier.placeFurniture(
          id,
          _placedPos[id]!,
          _placedScale[id] ?? 1.0,
        );
      }
    }
    if (!mounted) return;
    final n = ids.length;
    // 홈에 저장해도 미니룸 배치는 그대로 남겨둔다(다시 편집·재저장 가능).
    _snack(toBuy.isEmpty ? '$n개를 홈에 저장했어요!' : '$n개를 구매해서 홈에 배치했어요!');
  }

  List<RoomItem> get _filtered =>
      kRoomItems.where((e) => _cat.matches(e)).toList();

  int get _cartTotal => kRoomItems
      .where((e) => _cart.contains(e.id))
      .fold(0, (sum, e) => sum + e.price);

  void _toggleCart(RoomItem item) {
    setState(() {
      _cart.contains(item.id) ? _cart.remove(item.id) : _cart.add(item.id);
    });
  }

  Future<void> _buy(int paws) async {
    if (_cart.isEmpty) return;
    // 펫이 없으면 구매·배치가 전부 no-op이 된다(발자국도 안 깎임).
    // 조용히 실패하면 "구매가 안 된다"로만 보이므로 이유를 알려준다.
    if (ref.read(petProvider) == null) {
      _snack('아직 네발 친구가 없어요. 온보딩을 먼저 완료해 주세요');
      return;
    }
    final total = _cartTotal;
    if (paws < total) {
      // 발자국이 모자라면 충전 페이지로 보낸다.
      _snack('발자국이 부족해요. 충전 페이지로 이동할게요.');
      context.push('/charge');
      return;
    }
    final ids = _cart.toList();
    await ref.read(petProvider.notifier).purchaseItems(ids, total);
    setState(() => _cart.clear());
    _snack('${ids.length}개 구매 완료! 홈 아이템창에서 사용할 수 있어요');
  }

  /// 마켓 구매하기: 하단 시트를 열어 상품값 + (선택) 기부 2개를 함께 결제한다.
  ///
  /// 지금은 뼈다귀 차감까지만 하고, 결제·배송 연동은 아직 없다.
  Future<void> _gift(MarketItem item) async {
    final pet = ref.read(petProvider);
    if (pet == null) {
      _snack('아직 네발 친구가 없어요. 온보딩을 먼저 완료해 주세요');
      return;
    }

    final result = await showModalBottomSheet<({bool donate, int total})>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PurchaseSheet(item: item, bones: pet.bones),
    );
    if (result == null || !mounted) return;

    final now = ref.read(petProvider);
    if (now == null || now.bones < result.total) {
      _snack('뼈다귀가 부족해요. (필요 ${result.total}개 / 보유 ${now?.bones ?? 0}개)');
      return;
    }

    await ref.read(petProvider.notifier).spendBones(result.total);
    if (result.donate) {
      // 기부분은 캠페인 진행률(구조 마릿수)에도 그대로 반영된다.
      ref.read(campaignProvider.notifier).join(_PurchaseSheet.donationBones);
    }
    if (!mounted) return;
    _snack(
      result.donate
          ? '${item.name} 구매 + 뼈다귀 ${_PurchaseSheet.donationBones}개 기부 완료! 고마워요'
          : '${item.name}을(를) 구매했어요. 고마워요!',
    );
  }

  /// 기부 캠페인 참여: 뼈다귀를 보내면 구조 마릿수가 올라가고,
  /// 그에 맞춰 진행률(%)과 게이지도 함께 움직인다.
  Future<void> _joinCampaign() async {
    final pet = ref.read(petProvider);
    if (pet == null) return;
    final need = ref.read(campaignProvider).bonesToJoin;
    if (pet.bones < need) {
      _snack('뼈다귀가 부족해요. (필요 $need개 / 보유 ${pet.bones}개)');
      return;
    }
    await ref.read(petProvider.notifier).spendBones(need);
    ref.read(campaignProvider.notifier).join(need);
    if (!mounted) return;
    _snack('뼈다귀 $need개로 마음을 전했어요. 고마워요!');
  }

  /// 자동 구매 전 확인 다이얼로그 (상품명 + 총 비용).
  Future<bool?> _confirmPurchase(String names, int cost) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '구매하시겠어요?',
          style: AppText.body(size: 16, weight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(names, style: AppText.body(size: 13, color: AppColors.ink)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '총 비용  ',
                  style: AppText.body(size: 13, color: AppColors.subtle),
                ),
                Image.asset(
                  'assets/icons/paw.png',
                  width: 14,
                  height: 14,
                  filterQuality: FilterQuality.none,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_comma(cost)}발자국',
                  style: AppText.body(
                    size: 15,
                    weight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '취소',
              style: AppText.body(
                size: 14,
                color: AppColors.subtle,
                weight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '구매',
              style: AppText.body(
                size: 14,
                color: AppColors.primary,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: AppText.body(size: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // 다른 화면에서 "마켓 탭으로 열어줘" 요청이 오면 그 탭으로 바꾸고 요청을 비운다.
    ref.listen(storeTabRequestProvider, (_, req) {
      if (req == null) return;
      setState(() => _tab = req == StoreTab.market ? 1 : 0);
      ref.read(storeTabRequestProvider.notifier).consume();
    });

    final pet = ref.watch(petProvider);
    final paws = pet?.paws ?? 0;
    final bones = pet?.bones ?? 0;
    final owned = pet?.ownedItems.toSet() ?? const <String>{};
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: Stack(
        children: [
          Column(
            children: [
              _Header(paws: paws, bones: bones, topPad: topPad),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _hPad(context),
                  24,
                  _hPad(context),
                  0,
                ),
                child: _TabToggle(
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              Expanded(
                child: _tab == 0
                    ? _buildMiniroom(owned)
                    : kMarketReady
                        ? _MarketTab(
                            campaign: ref.watch(campaignProvider),
                            onGift: _gift,
                            onJoinCampaign: _joinCampaign,
                          )
                        : const _MarketComingSoon(),
              ),
            ],
          ),
          // 장바구니 바: 콘텐츠 위에 떠 있고, 미니룸 스크롤 하단 여백으로 겹침 방지.
          if (_tab == 0 && _cart.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CartBar(
                count: _cart.length,
                total: _cartTotal,
                onBuy: () => _buy(paws),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniroom(Set<String> owned) {
    final items = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 카테고리: '전체' 단독 pill + 나머지 3개를 한 흰색 pill에 균등 배치해 좌우로 꽉 채운다.
        Padding(
          padding: EdgeInsets.fromLTRB(_hPad(context), 16, _hPad(context), 12),
          child: SizedBox(
            height: 42,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CategoryChip(
                  label: _StoreCat.all.label,
                  icon: _StoreCat.all.icon,
                  selected: _cat == _StoreCat.all,
                  onTap: () => setState(() => _cat = _StoreCat.all),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        for (final c in const [
                          _StoreCat.interior,
                          _StoreCat.costume,
                          _StoreCat.trick,
                        ])
                          Expanded(
                            child: _CatGroupItem(
                              label: c.label,
                              icon: c.icon!,
                              selected: _cat == c,
                              onTap: () => setState(() => _cat = c),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            // 장바구니 바가 뜰 때 마지막 줄이 바에 가리지 않도록 하단 여백 확보.
            padding: EdgeInsets.fromLTRB(
              _hPad(context),
              8,
              _hPad(context),
              _cart.isNotEmpty ? 100 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoomPreview(
                  placed: _placedList,
                  equipped: _tryOn.toList(),
                  appearance: switch (ref.watch(petProvider)) {
                    final p? => DogAppearance.fromPet(p),
                    null => const DogAppearance(),
                  },
                  activeItem: _previewItem == null
                      ? null
                      : kRoomItems.firstWhere(
                          (e) => e.id == _previewItem,
                          orElse: () => kRoomItems.first,
                        ),
                  activePos: _previewPos,
                  activeScale: _previewScale,
                  onMove: (d) => setState(() {
                    _previewPos = Offset(
                      (_previewPos.dx + d.dx).clamp(0.06, 0.94),
                      (_previewPos.dy + d.dy).clamp(0.14, 0.92),
                    );
                  }),
                  onResize: (delta) => setState(() {
                    _previewScale = (_previewScale + delta).clamp(
                      _previewMin,
                      _previewMax,
                    );
                  }),
                  onConfirm: _confirmPreview,
                  onCancel: _cancelPreview,
                  onEditPlaced: (id) => _pickPreview(
                    kRoomItems.firstWhere(
                      (e) => e.id == id,
                      orElse: () => kRoomItems.first,
                    ),
                  ),
                ),
                if (_hasPreview) ...[
                  const SizedBox(height: 10),
                  _SaveToHomeButton(onTap: _saveToHome),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      '전체상품',
                      style: AppText.body(size: 15, weight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      '신상품순',
                      style: AppText.body(
                        size: 13,
                        color: const Color(0xCC000000),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      'assets/icons/chevron_down.png',
                      width: 16,
                      height: 16,
                      color: const Color(0xCC000000),
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        '준비 중인 카테고리예요',
                        style: AppText.body(size: 14, color: AppColors.subtle),
                      ),
                    ),
                  )
                else
                  GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // 이미지가 남는 높이를 흡수하므로(카드의 Expanded) 이 값은
                    // 이미지 영역이 대략 정사각으로 보이는 지점으로만 잡으면 된다.
                    childAspectRatio: 0.60,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final item in items)
                        _ProductCard(
                          item: item,
                          owned: owned.contains(item.id),
                          inCart: _cart.contains(item.id),
                          selected:
                              _previewItem == item.id ||
                              _placedPos.containsKey(item.id) ||
                              _tryOn.contains(item.id),
                          onToggle: () => _toggleCart(item),
                          onPick: () => _pickPreview(item),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _comma(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

String _comma(int n) => _StorePageState._comma(n);

// ── 상단 오렌지 헤더 ──
class _Header extends StatelessWidget {
  const _Header({
    required this.paws,
    required this.bones,
    required this.topPad,
  });
  final int paws;
  final int bones;
  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      // 좌우 모두 본문(카테고리·상품 목록)과 같은 여백 → 양끝이 콘텐츠와 맞는다.
      padding: EdgeInsets.only(
        top: topPad + 62,
        left: _hPad(context),
        right: _hPad(context),
        bottom: 14,
      ),
      child: Row(
        children: [
          // Expanded: 제목이 남는 폭을 전부 차지해 칩·장바구니를 오른쪽 끝까지 민다.
          // (Flexible + Spacer로 두면 둘이 남는 폭을 반씩 나눠 갖고, 제목이 안 쓴
          //  몫이 Row 끝에 빈 공간으로 남아 오른쪽만 넓어 보인다)
          Expanded(
            child: Text(
              '스토어',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                family: 'Pretendard',
                size: 23,
                color: Colors.white,
                weight: FontWeight.w800,
              ),
            ),
          ),
          // 두 화폐를 나란히: 발자국(아이템) / 뼈다귀(마켓 실물).
          WalletChip.paws(
            _comma(paws),
            onTap: () => context.push('/charge'),
          ),
          // 마켓이 닫혀 있는 동안 뼈다귀는 감춘다(kBonesEnabled).
          if (kBonesEnabled) ...[
            const SizedBox(width: 8),
            WalletChip.bones(_comma(bones)),
          ],
          const SizedBox(width: 10),
          // 장바구니(원형). 헤더 오렌지보다 진한 색이라 배경 위에서 떠 보인다.
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFC6F00),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/icons/cart.png',
              width: 18,
              height: 18,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 미니룸 / 마켓 탭 토글 ──
class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          _seg(0, '미니룸', 'assets/icons/tab_miniroom.png'),
          _seg(1, '마켓', 'assets/icons/tab_market.png'),
        ],
      ),
    );
  }

  // 선택: 배경 #FFF8F0 / 글자·아이콘 #F4845F, 미선택: 배경 #fff / #888888
  static const Color _selBg = Color(0xFFFFF8F0);
  static const Color _selFg = Color(0xFFF4845F);
  static const Color _unselBg = Color(0xFFFFFFFF);
  static const Color _unselFg = Color(0xFF888888);

  Widget _seg(int i, String label, String iconAsset) {
    final selected = index == i;
    final fg = selected ? _selFg : _unselFg;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(i),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? _selBg : _unselBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconAsset,
                width: 20,
                height: 20,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 카테고리 칩 ──
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4845F) : Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Image.asset(icon!, height: 24, filterQuality: FilterQuality.none),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 그룹 카테고리 항목 (흰색 pill 안에서 균등 분할, 선택 시 오렌지 pill) ──
class _CatGroupItem extends StatelessWidget {
  const _CatGroupItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: selected
            ? BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, height: 17, filterQuality: FilterQuality.none),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "이대로 홈에 저장" 버튼 (미리보기 배치를 홈에 반영) ──
class _SaveToHomeButton extends StatelessWidget {
  const _SaveToHomeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_filled, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(
              '이대로 홈에 저장',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 방 미리보기 (배경 + 강아지 + 여러 상품 배치 미리보기) ──
// [placed] 확정된 아이템들 / [activeItem] 지금 옮기는 중인 아이템.
// 활성 아이템: 드래그 이동, 네 모서리 핸들로 크기 조절, ✓ 확정 / ✗ 제거.
// 확정 아이템: 탭하면 다시 편집(onEditPlaced).
class _RoomPreview extends StatelessWidget {
  const _RoomPreview({
    this.placed = const [],
    this.equipped = const [],
    this.appearance = const DogAppearance(),
    this.activeItem,
    this.activePos = const Offset(0.5, 0.58),
    this.activeScale = 1.0,
    this.onMove,
    this.onResize,
    this.onConfirm,
    this.onCancel,
    this.onEditPlaced,
  });

  final List<({RoomItem item, Offset pos, double scale})> placed;
  final List<String> equipped; // 프리뷰 강아지에 입혀볼 코스튬 id
  final DogAppearance appearance; // 프리뷰 강아지 외형(홈과 동일해야 함)
  final RoomItem? activeItem;
  final Offset activePos; // 방 안 정규화 좌표(0~1)
  final double activeScale;
  final void Function(Offset normalizedDelta)? onMove;
  final void Function(double scaleDelta)? onResize;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final void Function(String id)? onEditPlaced;

  static Widget _itemImage(RoomItem item, double box) => item.asset != null
      ? Image.asset(
          item.asset!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        )
      : Icon(item.icon, size: box * 0.8, color: AppColors.brownIcon);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: AspectRatio(
        aspectRatio: 16 / 8.2,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            final base = h * 0.4; // 상품 기본 크기(방 높이 비례)
            final active = activeItem;
            final abox = base * activeScale;
            final acx = activePos.dx * w;
            final acy = activePos.dy * h;
            const hs = 22.0; // 모서리 핸들 히트 영역
            const corners = [
              (-1.0, -1.0),
              (1.0, -1.0),
              (-1.0, 1.0),
              (1.0, 1.0),
            ];
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/room_bg.webp',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFFF3E6CC)),
                ),
                Align(
                  alignment: const Alignment(0.55, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    // 홈과 동일한 강아지+웨어러블 위젯(150 설계)을 96 크기로 스케일.
                    child: SizedBox(
                      width: 96 * DogWithWearables.designBox / 130,
                      height: 96 * DogWithWearables.designBox / 130,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: DogWithWearables(
                          equipped: equipped,
                          appearance: appearance,
                        ),
                      ),
                    ),
                  ),
                ),
                // 확정된 아이템들 (탭하면 다시 편집)
                for (final p in placed)
                  Positioned(
                    left: p.pos.dx * w - base * p.scale / 2,
                    top: p.pos.dy * h - base * p.scale / 2,
                    width: base * p.scale,
                    height: base * p.scale,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onEditPlaced?.call(p.item.id),
                      child: _itemImage(p.item, base * p.scale),
                    ),
                  ),
                // 활성(옮기는 중) 아이템: 이동/크기조절/확정/제거
                if (active != null) ...[
                  Positioned(
                    left: acx - abox / 2,
                    top: acy - abox / 2,
                    width: abox,
                    height: abox,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (d) =>
                          onMove?.call(Offset(d.delta.dx / w, d.delta.dy / h)),
                      child: _itemImage(active, abox),
                    ),
                  ),
                  // 선택 프레임
                  Positioned(
                    left: acx - abox / 2,
                    top: acy - abox / 2,
                    width: abox,
                    height: abox,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // 네 모서리 크기 조절 핸들
                  for (final cn in corners)
                    Positioned(
                      left: acx - abox / 2 + (cn.$1 < 0 ? 0.0 : abox) - hs / 2,
                      top: acy - abox / 2 + (cn.$2 < 0 ? 0.0 : abox) - hs / 2,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (d) => onResize?.call(
                          (d.delta.dx * cn.$1 + d.delta.dy * cn.$2) / base,
                        ),
                        child: Center(
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // ✓ 확정 / ✗ 제거
                  Positioned(
                    left: acx + abox / 2 - 30,
                    top: acy - abox / 2 - 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MiniBtn(
                          icon: Icons.close,
                          bg: AppColors.ink.withValues(alpha: 0.72),
                          onTap: onCancel,
                        ),
                        const SizedBox(width: 4),
                        _MiniBtn(
                          icon: Icons.check,
                          bg: AppColors.primary,
                          onTap: onConfirm,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// 미리보기의 확정(✓)/제거(✗) 미니 버튼.
class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.icon, required this.bg, this.onTap});
  final IconData icon;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }
}

// ── 상품 카드 ──
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.owned,
    required this.inCart,
    required this.selected,
    required this.onToggle,
    required this.onPick,
  });
  final RoomItem item;
  final bool owned;
  final bool inCart;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 상품 카드 배경 #F4F0EB (제품 이미지 영역은 흰색 유지).
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0EB),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 이미지 카드 (탭 → 방 미리보기에 배치).
          // Expanded: 이름·가격·버튼을 먼저 앉히고 남는 높이를 이미지가 가져간다.
          // 정사각으로 고정하면 셀이 조금만 짧아도 카드가 넘치고(노란 줄무늬),
          // 반대로 셀이 길면 버튼 아래가 남는다.
          Expanded(
            child: GestureDetector(
              onTap: onPick,
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFFEDE9E1),
                    width: selected ? 1.8 : 1.4,
                  ),
                ),
                // 홈 아이템창과 같은 규칙: 흰 칸의 86%를 그림이 차지한다.
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.86,
                  heightFactor: 0.86,
                  child: item.asset != null
                      ? Image.asset(
                          item.asset!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        )
                      : FittedBox(
                          fit: BoxFit.contain,
                          child: Icon(item.icon, color: AppColors.brownIcon),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.body(size: 12, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          // 가격
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/paw.png',
                width: 13,
                height: 13,
                filterQuality: FilterQuality.none,
              ),
              const SizedBox(width: 3),
              Text(
                '${item.price}',
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: const Color(0xFF464646),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 담기 / 보유 버튼
          owned
              ? Container(
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EDE2),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 13,
                        color: AppColors.subtle,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '보유',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.subtle,
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 26,
                    decoration: BoxDecoration(
                      color: inCart ? Colors.white : AppColors.primary,
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(color: AppColors.primary, width: 1.4),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          inCart ? Icons.check : Icons.add_shopping_cart,
                          size: 13,
                          color: inCart ? AppColors.primary : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inCart ? '담음' : '담기',
                          style: AppText.body(
                            size: 12,
                            weight: FontWeight.w700,
                            color: inCart ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── 장바구니 하단 바 ──
class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.count,
    required this.total,
    required this.onBuy,
  });
  final int count;
  final int total;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        // 좌우로 벌리지 않고 한 덩어리로 가운데 정렬한다.
        // scaleDown: 폭이 모자라면 넘치는 대신 한 덩어리로 줄어든다.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                '장바구니',
                style: AppText.body(
                  size: 16,
                  color: Colors.white,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(500),
                ),
                child: Text(
                  '$count',
                  style: AppText.body(
                    size: 13,
                    color: AppColors.primary,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              // 구분선
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: const Color(0x66FFFFFF),
              ),
              Text(
                '총 ${_comma(total)}발자국',
                style: AppText.body(
                  size: 16,
                  color: Colors.white,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onBuy,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    '구매하기',
                    style: AppText.body(
                      size: 14,
                      color: AppColors.primary,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 마켓 오픈 여부. 정산 계좌가 준비되기 전까지는 "준비중" 안내만 보여준다.
/// 다시 열 때는 `--dart-define=MARKET_READY=true` 로 빌드.
final bool kMarketReady = const bool.fromEnvironment('MARKET_READY');

/// 마켓 준비중 안내: 로고 + 공사중 강아지 + 안내 문구 + 커뮤니티로 이동.
class _MarketComingSoon extends StatelessWidget {
  const _MarketComingSoon();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(_hPad(context), 24, _hPad(context), 32),
      child: Column(
        children: [
          Image.asset(
            'assets/images/heeheehoho_arc.png',
            width: 220,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(height: 18),
          Image.asset(
            'assets/images/store_ready_dog.webp',
            width: 200,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(height: 24),
          // 🚧 스토어 준비중입니다 🚧
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/icons/ic_barrier.png', width: 26, height: 26),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '스토어 준비중입니다',
                  textAlign: TextAlign.center,
                  style: AppText.pixel(
                    size: 30,
                    height: 1.2,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Image.asset('assets/icons/ic_barrier.png', width: 26, height: 26),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '다양한 아이템들을 가득 담아\n열심히 준비하고 있습니다.\n잠시만 기다려주세요!',
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 20,
              weight: FontWeight.w500,
              height: 1.5,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go('/community'),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFD8B3E),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text(
                '커뮤니티 둘러보기',
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w800,
                  color: const Color(0xFFFFFEFD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 마켓 탭: 기부 캠페인 + 광고 + 뼈다귀로 선물하는 실제 상품들 ──
class _MarketTab extends StatelessWidget {
  const _MarketTab({
    required this.campaign,
    required this.onGift,
    required this.onJoinCampaign,
  });

  final DonationCampaign campaign;
  final void Function(MarketItem item) onGift;
  final VoidCallback onJoinCampaign;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(_hPad(context), 16, _hPad(context), 24),
      children: [
        _CampaignCard(campaign: campaign, onJoin: onJoinCampaign),
        const SizedBox(height: 20),
        const _AdCard(),
        const SizedBox(height: 20),
        for (final item in kMarketItems) ...[
          _MarketCard(item: item, onGift: () => onGift(item)),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

/// 이번 달 기부 캠페인: 진행률 + "뼈다귀로 마음 전하기".
class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.onJoin});

  final DonationCampaign campaign;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final percent = (campaign.progress * 100).round();

    // IntrinsicHeight: 오른쪽 "마음 전하기" 버튼이 왼쪽 글 높이에 맞춰 늘어나게.
    // (ListView 안에서는 높이가 무한이라 stretch만 쓰면 렌더가 터진다)
    return Padding(
      // 위쪽은 탭 토글과 떨어지도록 더 넉넉히.
      padding: const EdgeInsets.fromLTRB(6, 20, 6, 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/paw.png',
                        width: 13,
                        height: 13,
                        filterQuality: FilterQuality.none,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '이번 달 기부 캠페인',
                        style: AppText.body(
                          size: 9.53,
                          weight: FontWeight.w700,
                          color: const Color(0xFFC0905A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 제목 끝에 발자국 아이콘을 글자처럼 붙인다.
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: campaign.title),
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Image(
                              image: AssetImage('assets/icons/paw.png'),
                              width: 13,
                              height: 13,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '진행률',
                        style: AppText.body(
                          size: 12,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$percent%',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w700,
                          color: const Color(0xFFF4845F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _ProgressGauge(value: campaign.progress),
                  const SizedBox(height: 7),
                  Text(
                    '${_comma(campaign.rescued)}마리 구조 완료 · '
                    '목표 ${_comma(campaign.goal)}마리',
                    style: AppText.body(
                      size: 12,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Center: 세로로 늘어나지 않고 내용 크기만큼만 차지한다.
            // (stretch로 두면 왼쪽 글 높이에 맞춰 늘어나서 padding을 줄여도 높이가 그대로다)
            Center(
              child: GestureDetector(
                onTap: onJoin,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6F00),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 4,
                        spreadRadius: -2,
                        offset: Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 6,
                        spreadRadius: -1,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  // min: 내용 높이만큼만. max면 다시 세로로 늘어난다.
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/bone.png',
                        width: 32,
                        height: 32,
                        filterQuality: FilterQuality.none,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${campaign.bonesToJoin}개로\n마음 전하기',
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          size: 12,
                          height: 1.35,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 캠페인 진행률 게이지. 채워지는 부분이 노랑(#FFD166) → 코랄(#F4845F) 그라디언트다.
/// 그라디언트는 채워진 길이만큼이 아니라 **게이지 전체 길이** 기준이라,
/// 진행률이 낮아도 색이 노랑에서 시작해 자연스럽게 이어진다.
class _ProgressGauge extends StatelessWidget {
  const _ProgressGauge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(500),
      child: Container(
        height: 7,
        color: Colors.white,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            // heightFactor가 없으면 채움 막대가 높이 0이 돼 아예 안 보인다.
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(500),
                gradient: LinearGradient(
                  colors: const [Color(0xFFFFD166), Color(0xFFF4845F)],
                  // 채워진 폭이 전체의 일부라도 색 구간은 전체 기준으로 잡는다.
                  end: Alignment((2 / value.clamp(0.05, 1.0)) - 1, 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 제휴 광고 배너.
class _AdCard extends StatelessWidget {
  const _AdCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDE5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '반려동물과 함께하는 공간을 위한\n방향 ∙ 탈취제, 포카앤빌리',
                  style: AppText.body(
                    family: 'Pretendard',
                    size: 14,
                    height: 1.45,
                    weight: FontWeight.w700,
                    color: const Color(0xFF282828),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF747474),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AD',
                        style: AppText.body(
                          family: 'Pretendard',
                          size: 8,
                          weight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '제품 바로가기  ›',
                      style: AppText.body(
                        family: 'Pretendard',
                        size: 10,
                        color: const Color(0xFF747474),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 광고 썸네일은 81:60 비율.
          const _ProductThumb.sized(
            asset: 'assets/market/ad_banner.png',
            width: 81,
            height: 60,
          ),
        ],
      ),
    );
  }
}

/// 마켓 상품 카드: 사진 + 뱃지 + 뼈다귀 가격 + 가상체험/구매하기.
class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.item, required this.onGift});

  final MarketItem item;
  final VoidCallback onGift;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFEDE9E1), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사진은 1:1 정사각 고정. 오른쪽 글(뱃지~가격 줄)의 높이와 같은 값이라
          // 사진 하단과 "5개" 줄 하단이 맞는다.
          //
          // AspectRatio를 IntrinsicHeight 안에 넣으면 안 된다 — 폭이 높이를,
          // 높이가 폭을 참조해서 사진이 걷잡을 수 없이 커진다.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumb(asset: item.asset, size: 100),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.badge case final badge?) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(500),
                            border: Border.all(
                              // #F4845F 30%
                              color: const Color(
                                0xFFF4845F,
                              ).withValues(alpha: .3),
                            ),
                          ),
                          child: Text(
                            badge,
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.w400,
                              color: const Color(0xFFF4845F),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        item.name,
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: AppText.body(
                          size: 12,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/bone.png',
                            width: 20,
                            height: 20,
                            filterQuality: FilterQuality.none,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${item.bones}개',
                            style: AppText.body(
                              size: 16,
                              weight: FontWeight.w700,
                              color: const Color(0xFFF4845F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MarketButton(
                  label: '가상 체험',
                  iconAsset: 'assets/icons/virtual.png',
                  filled: false,
                  // 가상 체험(강아지에게 미리 먹여보기)은 아직 화면이 없다.
                  onTap: null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MarketButton(
                  label: '구매하기',
                  iconAsset: 'assets/icons/gift.png',
                  filled: true,
                  onTap: onGift,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketButton extends StatelessWidget {
  const _MarketButton({
    required this.label,
    required this.iconAsset,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final String iconAsset;

  /// true = 구매하기(오렌지 채움), false = 가상 체험(흰 배경 + 초록 글자).
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 가상 체험 글자색 #76C442 / 구매하기 배경 #FB9244.
    final fg = filled ? Colors.white : const Color(0xFF76C442);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFB9244) : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: filled ? null : Border.all(color: const Color(0xFFDBDDD9)),
          // 그림자는 구매하기(채운 버튼)에만. 가상 체험은 테두리만.
          boxShadow: filled
              ? const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 2,
                    spreadRadius: -1,
                    offset: Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              width: 16,
              height: 16,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppText.body(size: 14, weight: FontWeight.w700, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상품 사진. 사진 에셋이 없거나 로드에 실패하면 회색 자리표시자를 그린다.
///
/// 세 가지로 쓰인다: 정사각, 81:60(광고 배너), 그리고 [fill] — 높이를 부모가 주는 대로
/// 채워서 옆에 있는 글 높이에 딱 맞추는 형태(마켓 상품 카드).
class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.asset, required double size})
    : width = size,
      height = size;

  const _ProductThumb.sized({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String? asset;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
      width: width,
      height: height,
      color: const Color(0xFFEFEBE4),
      alignment: Alignment.center,
      child: Icon(
        Icons.photo_outlined,
        size: (width ?? 60) * 0.32,
        color: AppColors.subtle,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: asset == null
          ? placeholder()
          : Image.asset(
              asset!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder(),
            ),
    );
  }
}

/// 마켓 구매 하단 시트: 상품값 + (선택) 기부 2개를 함께 결제한다.
///
/// 기부를 켜면 합계에 [donationBones]가 더해지고, 그만큼 캠페인 구조 마릿수도 올라간다.
class _PurchaseSheet extends StatefulWidget {
  const _PurchaseSheet({required this.item, required this.bones});

  /// 구매에 얹을 수 있는 기부 뼈다귀 개수.
  static const int donationBones = 2;

  final MarketItem item;

  /// 현재 보유 뼈다귀 (부족하면 버튼을 막는다).
  final int bones;

  @override
  State<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends State<_PurchaseSheet> {
  bool _donate = true;

  int get _total =>
      widget.item.bones + (_donate ? _PurchaseSheet.donationBones : 0);

  @override
  Widget build(BuildContext context) {
    final enough = widget.bones >= _total;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 손잡이
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE3DED5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.item.name,
            style: AppText.body(
              size: 16,
              weight: FontWeight.w800,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 14),
          _row('상품 금액', widget.item.bones),
          const SizedBox(height: 10),

          // 기부 얹기 (기본 켜짐)
          GestureDetector(
            onTap: () => setState(() => _donate = !_donate),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _donate
                      ? const Color(0xFFF4845F)
                      : const Color(0xFFEDE9E1),
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _donate ? Icons.check_circle : Icons.circle_outlined,
                    size: 20,
                    color: _donate
                        ? const Color(0xFFF4845F)
                        : const Color(0xFFCCBFB5),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '보호소 아이들에게 기부하기',
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '이번 달 캠페인 진행률에 함께 반영돼요',
                          style: AppText.body(
                            size: 11,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/icons/bone.png',
                    width: 16,
                    height: 16,
                    filterQuality: FilterQuality.none,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${_PurchaseSheet.donationBones}개',
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: const Color(0xFFF4845F),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEDE9E1)),
          const SizedBox(height: 14),
          _row('합계', _total, bold: true),
          const SizedBox(height: 6),
          Text(
            '보유 뼈다귀 ${widget.bones}개',
            style: AppText.body(size: 11, color: const Color(0xFF888888)),
          ),
          const SizedBox(height: 18),

          GestureDetector(
            onTap: enough
                ? () => Navigator.pop(context, (donate: _donate, total: _total))
                : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: enough
                    ? const Color(0xFFFB9244)
                    : const Color(0xFFE3DED5),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text(
                enough ? '$_total개로 구매하기' : '뼈다귀가 부족해요',
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, int bones, {bool bold = false}) => Row(
    children: [
      Text(
        label,
        style: AppText.body(
          size: bold ? 14 : 13,
          weight: bold ? FontWeight.w800 : FontWeight.w400,
          color: bold ? const Color(0xFF2D2D2D) : const Color(0xFF888888),
        ),
      ),
      const Spacer(),
      Image.asset(
        'assets/icons/bone.png',
        width: bold ? 20 : 16,
        height: bold ? 20 : 16,
        filterQuality: FilterQuality.none,
      ),
      const SizedBox(width: 5),
      Text(
        '$bones개',
        style: AppText.body(
          size: bold ? 16 : 13,
          weight: FontWeight.w800,
          color: const Color(0xFFF4845F),
        ),
      ),
    ],
  );
}
