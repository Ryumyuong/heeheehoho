import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/pixel_theme.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/domain/care_lines.dart';
import '../../pet/domain/dog_appearance.dart';
import '../../pet/domain/pet.dart';
import '../../pet/presentation/widgets/dog_with_wearables.dart';
import '../domain/room_item.dart';
import '../../../shared/widgets/wallet_chip.dart';
import 'widgets/stat_card.dart';
import 'widgets/item_panel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // 강아지가 걸을 때만 돌아가는 컨트롤러(배경 패럴랙스 스크롤).
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // 다른 앱에 갔다 돌아왔을 때도 그동안의 변화를 반영한다.
    if (s == AppLifecycleState.resumed) {
      ref.read(petProvider.notifier).applyDecay();
    }
  }

  /// 돌보기(밥·잠·놀기) 직후 말풍선에 띄우는 한마디. 잠시 뒤 기본 인사로 돌아간다.
  String? _careLine;
  Timer? _careTimer;

  /// 돌보기를 하고 그에 맞는 말을 띄운다.
  void _care(CareAction action, Future<void> Function() run) {
    run();
    _careTimer?.cancel();
    setState(() => _careLine = CareLines.pick(action));
    _careTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _careLine = null);
    });
  }

  bool _walking = false;
  bool _itemOpen = false;
  String? _pendingItem; // 배치 미리보기 중인 아이템 id
  Offset _pendingPos = const Offset(0.5, 0.5); // 미리보기 정규화 좌표(0~1)
  double _pendingScale = 1.0; // 미리보기 크기 배율
  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;

  // 걸을 때 방(배경 이미지)이 좌우로 움직이는 최대 가로 이동량(px).
  // build에서 실제 배경 표시 폭에 맞춰 갱신 → 배경 전체가 드러나도록 이동한다.
  double _panAmplitude = 120;

  // 배경 원본 비율(가로/세로). fitHeight 표시 폭 계산에 사용.
  static const double _bgAspect = 3596 / 1874;
  // 걷기 속도(px/s). 클수록 강아지 이동/배경 스크롤이 빨라진다.
  static const double _walkSpeed = 240;

  // 홈 헤더 높이(topPad 제외분). 배경/방은 이 아래(헤더~하단메뉴 사이)에 놓인다.
  static const double _headerH = 104;
  // MainShell 하단바 대략 높이(SafeArea 하단 제외): border1 + padding30 + SizedBox62.
  static const double _navChrome = 93;
  // build에서 갱신: 방(배경) 영역의 top 위치와 높이. 가구·미리보기 y좌표 기준.
  double _headerTopPx = 0;
  double _roomH = 1;

  // 아이템 패널 높이(ItemPanel.height와 동일). 배경은 그대로 두고 패널이 그 위를 덮는다.
  static const double _panelHeight = 250;

  // _DogWithWearables의 기본 박스 치수. 스케일의 기준값.
  static const double _dogBaseBox = 150;
  // 강아지 크기는 방 높이에 비례한다(폭 기준 아님). 값을 키우면 강아지가 커진다.
  static const double _dogRoomRatio = 0.26; // 강아지 박스 ÷ 방 높이

  /// 배경 이미지와 배치 가구가 공유하는 가로 패럴랙스 오프셋(px).
  /// 둘이 같은 값을 써야 속도가 일치하고 "보이는 그대로" 확정된다.
  double get _roomCamX {
    final u = _walk.value * 2;
    final tri = u <= 1 ? u : 2 - u; // 0 → 1 → 0
    // -amp → +amp → -amp : 좌·우 양끝까지 배경 전체를 훑는다.
    return (tri - 0.5) * 2 * _panAmplitude;
  }

  @override
  void initState() {
    super.initState();
    // 정지 상태에서 배경이 중앙에 오도록(camX=0) 위상을 0.25로 시작.
    _walk.value = 0.25;
    // 앱을 껐던 동안 흐른 시간만큼 상태값을 반영한다.
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(petProvider.notifier).applyDecay(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _careTimer?.cancel();
    _walk.dispose();
    super.dispose();
  }

  void _toggleWalk() {
    if (_itemOpen) return;
    setState(() => _walking = !_walking);
    _walking ? _walk.repeat() : _walk.stop();
  }

  void _toggleItemPanel() {
    setState(() {
      _itemOpen = !_itemOpen;
      if (_itemOpen) {
        _walking = false;
        _walk.stop();
      } else {
        _pendingItem = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petProvider);
    final name = pet?.name ?? '세미';
    final paws = pet?.paws ?? 0;
    final bones = pet?.bones ?? 0;
    final equipped = pet?.equippedItems ?? const [];
    final owned = pet?.ownedItems.toSet() ?? const <String>{};
    final appearance = pet == null
        ? const DogAppearance()
        : DogAppearance.fromPet(pet);
    final topPad = MediaQuery.of(context).padding.top;
    final size = MediaQuery.of(context).size;
    // 방(배경) 영역은 헤더 아래 ~ 하단메뉴 위까지.
    // HomePage 본문 높이 = 화면 - 하단바(약 93px + 하단 SafeArea). 이 값을 기준으로 잡아야
    // 배경 표시 폭이 정확해 팬(좌우 이동) 시 배경 가장자리가 드러나지 않는다.
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final bodyH = size.height - _navChrome - bottomPad;
    _headerTopPx = topPad + _headerH;
    _roomH = (bodyH - _headerTopPx).clamp(1.0, double.infinity);
    // 강아지 박스는 방 높이에 비례한다.
    final dogBox = _roomH * _dogRoomRatio;
    final dogScale = dogBox / _dogBaseBox;

    // 배경(fitHeight)의 표시 폭이 화면보다 넓은 만큼 좌우로 팬한다.
    // 남는 여백의 절반보다 살짝 덜 이동해(88%) 배경 끝(가장자리)이 화면에 드러나지 않게 한다.
    final bgDisplayW = _roomH * _bgAspect;
    _panAmplitude = ((bgDisplayW - size.width) / 2 * 0.88).clamp(
      0.0,
      double.infinity,
    );
    // 일정한 걷기 속도로 왕복(한 주기 = 4×amp 이동). 배경이 넓어도 속도 일정.
    final cycleSecs = (_panAmplitude * 4 / _walkSpeed).clamp(4.0, 16.0);
    final newDur = Duration(milliseconds: (cycleSecs * 1000).round());
    if (_walk.duration != newDur) {
      _walk.duration = newDur;
      if (_walking) _walk.repeat();
    }

    return Scaffold(
      backgroundColor: AppColors.splashOrange,
      body: Stack(
        children: [
          // ── 방 배경 (단일 이미지) ──
          // 세로를 영역 높이에 꽉 채워(위·아래 전부 보이게) 어느 폰 비율에서도 자연스럽게.
          // 아이템 패널이 열려도 배경은 그대로 두고, 패널이 배경 아래쪽을 덮는다.
          // 이미지는 영역보다 넓어지므로 걸을 때 가로로만 패럴랙스 이동한다.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            top: _headerTopPx,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _walk,
                builder: (context, _) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final bgH = constraints.maxHeight;
                      return OverflowBox(
                        minWidth: 0,
                        maxWidth: double.infinity,
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(-_roomCamX, 0),
                          child: SizedBox(
                            height: bgH,
                            child: Image.asset(
                              'assets/images/room_bg.webp',
                              fit: BoxFit.fitHeight,
                              filterQuality: FilterQuality.none,
                              // 이미지 로드 실패 시 벽 색으로 대체.
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(color: Color(0xFFF3E6CC)),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // ── 배치된 가구 (픽셀 에셋) : 배경과 함께 패럴랙스 스크롤 ──
          // 배경과 동일한 _roomCamX를 적용해 가구가 방에 '붙어' 같은 속도로 움직인다.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _walk,
              builder: (context, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: _buildPlacedFurniture(pet, size, _roomCamX),
                );
              },
            ),
          ),

          // ── 강아지 (탭=산책 토글) + 말풍선 + 장착 웨어러블 ──
          // 강아지와 말풍선을 같은 트랜스폼에 묶어 말풍선이 강아지를 따라가게 한다.
          // 아이템 패널이 열리면 강아지는 패널 바로 위로 내려와(기존보다 아래) 선다.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            // 닫혔을 때 강아지 하단 여백은 방 높이에 비례한다. 방이 짧은 펼친
            // 화면에선 낮게, 방이 긴 접은 화면에선 조금 높게 앉아 바닥에 붙는다.
            bottom: _itemOpen ? _panelHeight - 6 : _roomH * 0.11,
            child: AnimatedBuilder(
              animation: _walk,
              builder: (context, child) {
                // 강아지는 화면 중앙에서 제자리 걷기(다리 애니메이션)만 하고,
                // 실제 이동감은 배경·가구가 함께 스크롤되며 표현한다.
                // dx를 고정해 클릭으로 산책을 켜고 끌 때 순간이동(점프)이 없다.
                final u = _walk.value * 2;
                final facingRight = u <= 1;
                return Transform.translate(
                  offset: Offset.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_itemOpen && _pendingItem == null)
                        // 돌보기 직후에는 그 한마디를, 평소엔 기본 인사를.
                        _SpeechBubble(_careLine ??
                            (_walking ? '같이 산책 가자멍!' : '보고싶었다멍!')),
                      GestureDetector(
                        onTap: _toggleWalk,
                        // 726:220 비율에 맞춰 강아지+웨어러블을 통째로 균일 스케일.
                        child: SizedBox(
                          width: _dogBaseBox * dogScale,
                          height: _dogBaseBox * dogScale,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: DogWithWearables(
                              walking: _walking,
                              flip: _walking && !facingRight,
                              equipped: equipped,
                              appearance: appearance,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── 상단 오렌지 바 (미니룸 타이틀 / 포인트·알림) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topPad + _headerH,
              color: AppColors.splashOrange,
              padding: EdgeInsets.only(top: topPad + 48, left: 20, right: 18),
              child: Row(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: name,
                          style: AppText.body(
                            family: 'Pretendard',
                            size: 18,
                            color: Colors.white,
                            weight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: '의 미니룸',
                          style: AppText.body(
                            family: 'Pretendard',
                            size: 18,
                            color: Colors.white,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 발자국(아이템) / 뼈다귀(마켓 실물) — 스토어 헤더와 같은 칩.
                  WalletChip.paws(
                    _comma(paws),
                    onTap: () => context.push('/charge'),
                  ),
                  // 마켓이 닫혀 있는 동안 뼈다귀는 감춘다(kBonesEnabled).
                  if (kBonesEnabled) ...[
                    const SizedBox(width: 8),
                    WalletChip.bones(_comma(bones)),
                  ],
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/icons/bell.png',
                    width: 22,
                    height: 22,
                    filterQuality: FilterQuality.none,
                  ),
                ],
              ),
            ),
          ),

          // ── 스탯 카드 (좌상단, 밥주기와 같은 가로선) ──
          Positioned(
            top: topPad + 140,
            left: 28,
            child: StatCard(
              happiness: pet?.happiness ?? 70,
              hunger: pet?.hunger ?? 60,
              fatigue: pet?.fatigue ?? 40,
              // 좁은 화면에선 오른쪽 액션 버튼과 안 겹치도록 폭을 줄인다.
              width: (size.width - 155).clamp(150.0, 215.0),
            ),
          ),

          // ── 액션 버튼 (우상단, 오른쪽 끝에 붙임) ──
          Positioned(
            top: topPad + 140,
            right: 0,
            child: _ActionButtons(
              onFeed: () =>
                  _care(CareAction.feed, ref.read(petProvider.notifier).feed),
              onSleep: () =>
                  _care(CareAction.sleep, ref.read(petProvider.notifier).sleep),
              onPlay: () =>
                  _care(CareAction.play, ref.read(petProvider.notifier).play),
            ),
          ),

          // ── 가구 배치 미리보기 (드래그 이동 → X 취소 / ✓ 고정) ──
          if (_pendingItem != null) _buildDraggablePreview(size),

          // ── 아이템창 바깥 탭 감지(스크림) ── 패널이 열려 있을 때만.
          // 패널·ITEM 버튼은 이 아래(=위 레이어)에 있어 그대로 동작하고,
          // 그 밖의 화면을 탭하면 패널을 닫는다.
          if (_itemOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _itemOpen = false),
              ),
            ),

          // ── ITEM 버튼 ── 하단(=하단바 바로 위)에 붙인다.
          // 열리면 패널 위로 올라가 겹치지 않는다.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            right: 0,
            bottom: _itemOpen ? _panelHeight : 0,
            child: ItemToggleButton(open: _itemOpen, onTap: _toggleItemPanel),
          ),

          // ── 아이템 패널 ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: _itemOpen ? 0 : -_panelHeight,
            child: ItemPanel(
              equipped: equipped,
              owned: owned,
              pending: _pendingItem,
              onSelect: (item) {
                if (!owned.contains(item.id)) return; // 미보유는 사용 불가.
                if (item.category == ItemCategory.furniture) {
                  if (equipped.contains(item.id)) {
                    // 이미 배치된 가구를 다시 누르면 제거.
                    ref.read(petProvider.notifier).removeFurniture(item.id);
                  } else {
                    setState(() {
                      _pendingItem = item.id;
                      _pendingPos = const Offset(0.5, 0.5);
                      _pendingScale = 1.0;
                      _itemOpen = false; // 배경 전체를 드래그 캔버스로.
                    });
                  }
                } else {
                  ref.read(petProvider.notifier).toggleItem(item.id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // 가구 기준 크기: 미니룸 프리뷰(base = 방높이 × 0.4)와 동일한 공식으로 맞춰
  // 미니룸에서 본 위치·크기 비율이 홈에서도 그대로 유지되도록 한다.
  double get _furnitureSize => _roomH * 0.4;

  /// 저장된 정규화 좌표·크기대로 배치된 가구를 그린다. (탭하면 다시 이동/크기조절)
  /// [camX]는 배경 패럴랙스 오프셋 — 가구를 배경과 함께 좌우로 이동시킨다.
  List<Widget> _buildPlacedFurniture(Pet? pet, Size size, double camX) {
    final placements = pet?.placements ?? const <String, Offset>{};
    final scales = pet?.placementScales ?? const <String, double>{};
    final out = <Widget>[];
    placements.forEach((id, pos) {
      if (id == _pendingItem) return; // 이동 중인 가구는 미리보기로 대체.
      final item = kRoomItems.firstWhere(
        (e) => e.id == id,
        orElse: () => kRoomItems.first,
      );
      final fs = _furnitureSize * (scales[id] ?? 1.0);
      // 가구 x는 화면 폭이 아니라 '배경 이미지 실제 폭' 기준으로 매핑해야
      // 미니룸 프리뷰(방 전체 기준 배치)와 홈 위치가 일치한다.
      final bgW = _roomH * _bgAspect;
      final bgLeft = size.width / 2 - camX - bgW / 2;
      out.add(
        Positioned(
          left: bgLeft + pos.dx * bgW - fs / 2,
          top: _headerTopPx + pos.dy * _roomH - fs / 2,
          width: fs,
          child: GestureDetector(
            onTap: () => setState(() {
              _pendingItem = id;
              _pendingPos = pos;
              _pendingScale = scales[id] ?? 1.0;
              _itemOpen = false;
              // 위치를 다시 옮기는 동안엔 배경을 멈춰 미리보기와 어긋나지 않게.
              _walking = false;
              _walk.stop();
            }),
            child: _FurnitureSprite(item: item, size: fs),
          ),
        ),
      );
    });
    return out;
  }

  /// 선택된 가구를 프레임으로 감싸 표시한다.
  /// - 박스 본체 드래그 → 이동
  /// - 네 모서리 대각선 드래그 → 크기 조절 (중심 기준 확대/축소)
  /// - X 취소 / ✓ 고정
  Widget _buildDraggablePreview(Size size) {
    final item = kRoomItems.firstWhere((e) => e.id == _pendingItem);
    final box = _furnitureSize * _pendingScale;
    const ctrl = 30.0; // X / ✓ 버튼 영역 너비
    const h = 24.0; // 모서리 핸들 히트 영역
    // 배치된 가구와 동일한 좌표 매핑(배경 실제 폭 기준)으로 미리보기와 확정 위치를 일치시킨다.
    final bgW = _roomH * _bgAspect;
    final bgLeft = size.width / 2 - _roomCamX - bgW / 2;
    final cx = bgLeft + _pendingPos.dx * bgW;
    final cy = _headerTopPx + _pendingPos.dy * _roomH;
    // 각 모서리의 '바깥' 방향 부호 (TL, TR, BL, BR).
    const corners = [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)];
    return Positioned(
      left: cx - box / 2,
      top: cy - box / 2,
      child: SizedBox(
        width: box + h / 2 + ctrl,
        height: box + h / 2,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 드래그(이동) + 가구 이미지.
            Positioned(
              left: 0,
              top: 0,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() {
                  final nx = (_pendingPos.dx + d.delta.dx / bgW).clamp(
                    0.07,
                    0.93,
                  );
                  final ny = (_pendingPos.dy + d.delta.dy / _roomH).clamp(
                    0.12,
                    0.82,
                  );
                  _pendingPos = Offset(nx, ny);
                }),
                child: SizedBox(
                  width: box,
                  height: box,
                  child: _FurnitureSprite(item: item, size: box),
                ),
              ),
            ),
            // 선택 프레임 (테두리 1.2px / 모서리 3px).
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: CustomPaint(
                  size: Size(box, box),
                  painter: _SelectionFramePainter(color: AppColors.primary),
                ),
              ),
            ),
            // 네 모서리 크기 조절 핸들 (대각선 드래그).
            for (final c in corners)
              Positioned(
                left: (c.$1 < 0 ? 0.0 : box) - h / 2,
                top: (c.$2 < 0 ? 0.0 : box) - h / 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (d) => setState(() {
                    // 바깥 방향으로 끌면 +, 안쪽으로 끌면 - 로 배율 증감.
                    final delta =
                        (d.delta.dx * c.$1 + d.delta.dy * c.$2) /
                        _furnitureSize;
                    _pendingScale = (_pendingScale + delta).clamp(
                      _minScale,
                      _maxScale,
                    );
                  }),
                  child: const SizedBox(width: h, height: h),
                ),
              ),
            // X (취소)
            Positioned(
              right: 0,
              top: -6,
              child: _IconButton(
                'assets/icons/btn_cancel.png',
                () => setState(() => _pendingItem = null),
              ),
            ),
            // ✓ (고정)
            Positioned(
              right: 0,
              top: 26,
              child: _IconButton('assets/icons/btn_confirm.png', () {
                ref
                    .read(petProvider.notifier)
                    .placeFurniture(_pendingItem!, _pendingPos, _pendingScale);
                setState(() => _pendingItem = null);
              }),
            ),
          ],
        ),
      ),
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

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onFeed,
    required this.onSleep,
    required this.onPlay,
  });
  final VoidCallback onFeed;
  final VoidCallback onSleep;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    // 가장 긴 '놀아주기' 기준으로 세 버튼 폭을 통일.
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionPill(
            icon: 'assets/icons/action_feed.png',
            label: '밥주기',
            onTap: onFeed,
          ),
          const SizedBox(height: 10),
          _ActionPill(
            icon: 'assets/icons/action_sleep.png',
            label: '잠자기',
            onTap: onSleep,
          ),
          const SizedBox(height: 10),
          _ActionPill(
            icon: 'assets/icons/action_play.png',
            label: '놀아주기',
            onTap: onPlay,
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final String icon;
  final String label;
  final VoidCallback onTap;

  // 좌측만 둥근 배경: top-left 5px / bottom-left 5px.
  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(5),
    bottomLeft: Radius.circular(5),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: _radius,
      child: InkWell(
        borderRadius: _radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                icon,
                width: 26,
                height: 26,
                filterQuality: FilterQuality.none,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  color: Color(0xB3000000), // #000 70%
                  fontWeight: FontWeight.w600,
                  fontVariations: [FontVariation('wght', 600)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 배치된 가구/미리보기용 픽셀 스프라이트.
class _FurnitureSprite extends StatelessWidget {
  const _FurnitureSprite({required this.item, this.size = 88});
  final RoomItem item;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (item.asset != null) {
      return Image.asset(
        item.asset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
    }
    return Icon(item.icon, color: AppColors.brownIcon, size: size * 0.6);
  }
}

/// 선택된 가구를 감싸는 프레임: 테두리 1.2px, 네 모서리 브래킷만 3px.
class _SelectionFramePainter extends CustomPainter {
  _SelectionFramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(Offset.zero & size, edge);

    final corner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;
    final len = (size.width * 0.28).clamp(8.0, 18.0);
    final w = size.width, h = size.height;
    // 각 모서리의 ㄱ자 브래킷.
    canvas.drawLine(const Offset(0, 0), Offset(len, 0), corner);
    canvas.drawLine(const Offset(0, 0), Offset(0, len), corner);
    canvas.drawLine(Offset(w, 0), Offset(w - len, 0), corner);
    canvas.drawLine(Offset(w, 0), Offset(w, len), corner);
    canvas.drawLine(Offset(0, h), Offset(len, h), corner);
    canvas.drawLine(Offset(0, h), Offset(0, h - len), corner);
    canvas.drawLine(Offset(w, h), Offset(w - len, h), corner);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), corner);
  }

  @override
  bool shouldRepaint(covariant _SelectionFramePainter old) =>
      old.color != color;
}

/// 이미지 아이콘 버튼 (배치 미리보기의 X / ✓).
class _IconButton extends StatelessWidget {
  const _IconButton(this.asset, this.onTap);
  final String asset;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Image.asset(
          asset,
          width: 26,
          height: 26,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            text,
            style: AppText.body(size: 17, weight: FontWeight.w600),
          ),
        ),
        CustomPaint(size: const Size(18, 10), painter: _TailPainter()),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
