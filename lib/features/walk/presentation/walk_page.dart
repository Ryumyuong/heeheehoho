import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';
import '../../../shared/widgets/wallet_chip.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/domain/dog_appearance.dart';
import '../../pet/presentation/widgets/dog_with_wearables.dart';
import '../../pet/presentation/widgets/running_dog.dart';
import '../../store/application/campaign_providers.dart';
import '../application/walk_providers.dart';
import '../domain/walk_log.dart';
import 'widgets/walk_scenery.dart';

/// 산책 화면 좌우 여백. 시안(412px)에서 24px이고, 폭이 달라지면 함께 늘고 준다.
double _hPad(BuildContext context) => DesignScale.scaled(context, 24);

/// 산책 강아지 박스 크기 = min(폭 기준, 높이 기준). 홈과 같은 방식으로, 세로로
/// 긴 접은 화면은 폭이, 가로로 넓은 펼친 화면은 높이가 제한이 되어 적당해진다.
// 산책 강아지 크기. 폭·높이 중 좁은 쪽 기준.
double _dogBox(BuildContext context, {double scale = 1.0}) {
  final s = MediaQuery.of(context).size;
  return math.min(s.width * 0.40, s.height * 0.22) * scale;
}

const _stepsOrange = Color(0xFFFC8F40); // 걸음 수·발자국 숫자
const _distanceGreen = Color(0xFF7CBD66); // 산책거리 숫자
const _cardLine = Color(0xFFF0E8DE); // 흰 카드 테두리
const _sectionInk = Color(0xCC000000); // 섹션 제목 (#000 80%)
const _statLabel = Color(0x80000000); // 스탯 라벨 (#000 50%)
const _cardBg = Color(0xFFF8F6F2);

/// 산책 탭. 한 화면 안에서 세 단계를 오간다.
/// 시작 전([WalkPhase.ready]) → 산책 중([WalkPhase.walking]) → 결과([WalkPhase.finished]).
class WalkPage extends ConsumerStatefulWidget {
  const WalkPage({super.key});

  @override
  ConsumerState<WalkPage> createState() => _WalkPageState();
}

class _WalkPageState extends ConsumerState<WalkPage> {
  // 결과·배너 이미지는 좀 큰 편이라, 화면에 처음 뜰 때 디코딩되면 한 박자 늦게
  // 나타난다. 탭에 들어온 순간 미리 디코딩해 두면 결과 화면에서 바로 뜬다.
  static const _preload = [
    'assets/images/walk_result.png',
    'assets/images/walk_park.png',
    'assets/images/dog_run_1.png',
    'assets/images/dog_run_2.png',
    'assets/images/walk_bg_city.png',
  ];
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final path in _preload) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petProvider);
    final walk = ref.watch(walkProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _cardBg,
      body: Column(
        children: [
          _Header(
            paws: pet?.paws ?? 0,
            bones: pet?.bones ?? 0,
            topPad: topPad,
            // 첫 화면(ready)이 아닐 때만 뒤로가기를 보여 첫 화면으로 돌아간다.
            onBack: walk.phase == WalkPhase.ready
                ? null
                : () => _backToStart(context, ref, walk),
          ),
          Expanded(
            child: switch (walk.phase) {
              WalkPhase.ready => _ReadyBody(log: walk.log),
              WalkPhase.walking => _WalkingBody(
                session: walk.session,
                log: walk.log,
                run: walk.run,
              ),
              WalkPhase.finished => _ResultBody(
                session: walk.session,
                rewardedPaws: walk.rewardedPaws,
              ),
            },
          ),
        ],
      ),
    );
  }

  /// 산책 화면에서 첫 화면(랜딩)으로 돌아간다.
  /// 산책을 재는 중이면 실수로 기록이 사라지지 않게 한 번 확인한다.
  Future<void> _backToStart(
    BuildContext context,
    WidgetRef ref,
    WalkState walk,
  ) async {
    if (walk.run == WalkRun.running) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '산책을 그만둘까요?',
            style: AppText.body(size: 16, weight: FontWeight.w800),
          ),
          content: Text(
            '지금까지 걸은 기록은 저장되지 않아요.',
            style: AppText.body(size: 13, color: AppColors.subtle),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                '계속 걷기',
                style: AppText.body(size: 14, color: AppColors.subtle),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                '그만두기',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(walkProvider.notifier).exitToStart();
  }
}

// ── 상단 오렌지 헤더 (스토어와 같은 구성) ──
class _Header extends StatelessWidget {
  const _Header({
    required this.paws,
    required this.bones,
    required this.topPad,
    this.onBack,
  });

  final int paws;
  final int bones;
  final double topPad;

  /// null이 아니면 제목 앞에 뒤로가기 화살표를 보여준다.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: topPad + 62,
        left: _hPad(context),
        right: _hPad(context),
        bottom: 14,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              '산책하기',
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
          WalletChip.paws(
            _comma(paws),
            onTap: () => context.push('/charge'),
          ),
          const SizedBox(width: 8),
          WalletChip.bones(_comma(bones)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go('/store'),
            behavior: HitTestBehavior.opaque,
            child: Container(
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
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 1단계 — 산책 시작 전
// ══════════════════════════════════════════════
class _ReadyBody extends ConsumerWidget {
  const _ReadyBody({required this.log});

  final WalkLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = _hPad(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 24),
      children: [
        // 배너는 산책 화면을 열기만 한다. 실제 시작은 그 화면의 "산책 시작".
        _StartBanner(onTap: () => ref.read(walkProvider.notifier).open()),
        const SizedBox(height: 26),
        const _SectionTitle('오늘의 기록'),
        const SizedBox(height: 10),
        _StatTriple(
          items: [
            (
              // 오늘 누적 거리에서 어림잡은 걸음 수.
              icon: const _StatIcon(_StatIcon.steps),
              value: _comma(WalkMath.estimatedSteps(log.todayMeters)),
              label: '걸음 수',
              color: _stepsOrange,
            ),
            (
              icon: const _StatIcon(_StatIcon.paw),
              value: '+${_comma(log.todayPaws)}',
              label: '획득 발자국',
              color: _stepsOrange,
            ),
            (
              icon: const _StatIcon(_StatIcon.distance),
              value: '${log.todayKm.toStringAsFixed(1)}km',
              label: '산책거리',
              color: _distanceGreen,
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _SectionTitle('이번 주 산책현황'),
        const SizedBox(height: 10),
        _WeekStrip(done: log.weekdays),
        const SizedBox(height: 26),
        const _SectionTitle('발자국으로 할 수 있는 것'),
        const SizedBox(height: 10),
        _UseCard(
          rows: [
            (
              icon: 'assets/icons/use_item.png',
              title: '아이템 구매',
              subtitle: '우리 강아지 꾸미기',
              onTap: () => _openStore(ref, context, StoreTab.miniroom),
            ),
            (
              icon: 'assets/icons/use_donate.png',
              title: '유기견 후원하기',
              subtitle: '내 산책이 밥이 됩니다',
              // 후원은 마켓 탭(기부 캠페인)에서 이뤄진다.
              onTap: () => _openStore(ref, context, StoreTab.market),
            ),
          ],
        ),
      ],
    );
  }

  /// 스토어를 원하는 탭으로 연다. 탭 요청을 provider에 남기고 이동하면
  /// 스토어가 그 값을 읽어 해당 탭을 펼친다.
  void _openStore(WidgetRef ref, BuildContext context, StoreTab tab) {
    ref.read(storeTabRequestProvider.notifier).request(tab);
    context.go('/store');
  }
}

/// "산책 시작하기" 오렌지 배너. 탭하면 산책이 시작된다.
class _StartBanner extends StatelessWidget {
  const _StartBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 108,
        // linear-gradient(95.33deg, #FF9E57 8.69%, #F47C24 100%)
        // — 95.33deg는 왼→오른쪽에서 아주 살짝 아래로 기운 방향.
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-1, -0.09),
            end: Alignment(1, 0.09),
            colors: [Color(0xFFFF9E57), Color(0xFFF47C24)],
            stops: [0.0869, 1.0],
          ),
          border: Border.all(color: const Color(0xFFFF8E3B), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          // 테두리 안쪽으로 클립 → 일러스트가 모서리를 넘지 않는다.
          borderRadius: BorderRadius.circular(14.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 공원 일러스트는 오른쪽에 붙이고, 글자와 겹치지 않게 폭을 제한한다.
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Image.asset(
                    'assets/images/walk_park.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '산책 시작하기',
                      style: AppText.body(
                        size: 24,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '오늘도 우리 강아지와 함께 걸어봐요!',
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w500,
                        color: const Color(0xCCFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 이번 주 월~일 산책 여부. 산책한 요일은 오렌지 원 + 흰 발자국.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.done});

  /// 1=월 … 7=일.
  final Set<int> done;

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    return _Panel(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int d = 1; d <= 7; d++)
            Column(
              children: [
                Text(
                  _labels[d - 1],
                  style: AppText.body(
                    size: 12,
                    weight: d == today ? FontWeight.w700 : FontWeight.w400,
                    color: const Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset(
                  done.contains(d)
                      ? 'assets/icons/week_done.png'
                      : 'assets/icons/week_empty.png',
                  width: 32,
                  height: 32,
                  filterQuality: FilterQuality.medium,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// "발자국으로 할 수 있는 것" 카드 (연한 오렌지 행 목록).
class _UseCard extends StatelessWidget {
  const _UseCard({required this.rows});

  final List<
      ({String icon, String title, String subtitle, VoidCallback onTap})> rows;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            GestureDetector(
              onTap: rows[i].onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        rows[i].icon,
                        width: 22,
                        height: 22,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].title,
                          style: AppText.body(
                            size: 16,
                            weight: FontWeight.w700,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          rows[i].subtitle,
                          style: AppText.body(
                            size: 12,
                            weight: FontWeight.w700,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 2단계 — 산책 중
// ══════════════════════════════════════════════
class _WalkingBody extends ConsumerWidget {
  const _WalkingBody({
    required this.session,
    required this.log,
    required this.run,
  });

  final WalkSession session;

  /// 게이지는 이번 산책이 아니라 **오늘 누적 거리** 기준이라 함께 받는다.
  final WalkLog log;

  /// 대기 / 재는 중 / 종료.
  final WalkRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = _hPad(context);
    final pet = ref.watch(petProvider);
    // 위치·날씨는 늦게 도착하거나 실패할 수 있다. 그동안은 "위치 확인 중".
    final weather = ref
        .watch(walkWeatherProvider)
        .maybeWhen(data: (w) => w, orElse: () => WalkWeather.loading);
    final controller = ref.read(walkProvider.notifier);
    // 오늘 누적 걸음(이전 산책 + 이번 산책)과, 지금 받을 수 있는 발자국.
    final todaySteps = log.todaySteps + session.steps;
    final earnablePaws = WalkMath.claimablePaws(
      todaySteps: todaySteps,
      todayPaws: log.todayPaws,
    );
    // 종료했고 받을 발자국이 남아 있을 때만 보상을 받을 수 있다.
    final claimable = run == WalkRun.stopped && earnablePaws > 0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 14),
          child: _Panel(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        icon: const _StatIcon(_StatIcon.timer),
                        value: session.elapsedLabel,
                        label: '시간',
                        color: _stepsOrange,
                        valueSize: 24,
                      ),
                    ),
                    const _Divider(),
                    Expanded(
                      child: _MiniStat(
                        icon: const _StatIcon(_StatIcon.distance),
                        value: '${session.km.toStringAsFixed(2)}km',
                        label: '거리',
                        color: _distanceGreen,
                        valueSize: 24,
                      ),
                    ),
                    const _Divider(),
                    Expanded(
                      child: _MiniStat(
                        icon: const _StatIcon(_StatIcon.paw),
                        value: _comma(earnablePaws),
                        label: '획득 발자국',
                        color: _stepsOrange,
                        valueSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _GoalGauge(steps: todaySteps),
              ],
            ),
          ),
        ),
        // 배경은 좌우 여백 없이 꽉 채우고, 그 위에 칩·강아지·버튼을 얹는다.
        // 배경을 탭하면 테스트용으로 걷는 속도가 느리게 ↔ 빠르게 바뀐다.
        Expanded(
          child: GestureDetector(
            onTap: controller.toggleSpeed,
            behavior: HitTestBehavior.opaque,
            child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경은 강아지보다 빠르게 흘려 속도감을 준다(pace에 가중).
              WalkScenery(speed: session.pace * 1.8),
              Positioned(
                left: pad,
                top: 14,
                child: Row(
                  children: [
                    _GlassChip(
                      icon: weather.icon,
                      // 맑음만 픽셀 아이콘이 있고, 흐림·비·눈은 아직 이모지다.
                      asset: weather.icon == '☀️'
                          ? 'assets/icons/weather_sunny.png'
                          : null,
                      text: weather.temperature,
                    ),
                    const SizedBox(width: 8),
                    _GlassChip(
                      icon: '📍',
                      asset: 'assets/icons/pin.png',
                      text: weather.place,
                    ),
                  ],
                ),
              ),
              // 배경 그림의 흙길 위에 발이 닿도록 맞춘 위치.
              // 달리기는 전용 2프레임 스프라이트. 털색은 홈과 같은 방식으로 입힌다.
              Align(
                alignment: const Alignment(0, 0.34),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // 먼지가 먼저 그려져야 강아지 뒤로 간다.
                    Positioned(
                      right: 128,
                      bottom: 4,
                      child: _RunDust(speed: session.pace),
                    ),
                    // 느릴 땐 홈과 같은 걷기 모션(커스텀 외형·코스튬 그대로),
                    // 빨라지면 달리기 전용 스프라이트(아이템 착용)로 바뀐다.
                    if (session.isRunning)
                      RunningDog(
                        equipped: pet?.equippedItems ?? const [],
                        furColor: (pet == null
                                ? const DogAppearance()
                                : DogAppearance.fromPet(pet))
                            .furColor,
                        size: _dogBox(context),
                        // 발이 땅을 딛는 속도도 페이스를 따라간다. 2프레임이라
                        // 걷기~뛰기 구간은 차분하게, 더 빨리 뛰면 눈에 띄게 빨라지도록.
                        fps: (1.6 * session.pace).clamp(1.5, 7),
                      )
                    else
                      SizedBox(
                        width: _dogBox(context),
                        height: _dogBox(context),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: DogWithWearables(
                            equipped: pet?.equippedItems ?? const [],
                            appearance: pet == null
                                ? const DogAppearance()
                                : DogAppearance.fromPet(pet),
                            // 멈춰 있으면 다리도 멈춘다.
                            walking: session.pace > 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: pad,
                right: pad,
                bottom: 18,
                child: Row(
                  children: [
                    Expanded(
                      // 대기 → "산책 시작" / 재는 중 → "산책 종료"
                      // / 종료 후 → "다시 시작"(이어 걷기)
                      child: _WideButton(
                        label: switch (run) {
                          WalkRun.standby => '산책 시작',
                          WalkRun.running => '산책 종료',
                          WalkRun.stopped => '다시 시작',
                        },
                        background: const Color(0xFFFDEFDE),
                        foreground: Colors.black,
                        radius: 1.99,
                        onTap: run == WalkRun.running
                            ? controller.stop
                            : controller.begin,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WideButton(
                        label: '보상 받기',
                        background: const Color(0xFFFD8B3E),
                        // 비활성 상태에서도 배경은 그대로고 글자만 40%로 흐려진다.
                        foreground: claimable
                            ? const Color(0xFFFFFEFD)
                            : const Color(0x66FFFEFD),
                        // 산책을 종료해야 열린다.
                        enabled: claimable,
                        trailing: _PawIcon(
                          size: 16,
                          white: true,
                          opacity: claimable ? 1 : 0.4,
                        ),
                        onTap: controller.claim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 달리는 강아지 뒤에서 피어나는 먼지. 세 덩이가 시차를 두고 뒤로 밀려나며
/// 옅어진다. [speed]는 강아지·배경과 같은 배속이라 페이스가 빨라지면
/// 먼지도 함께 빨라진다.
class _RunDust extends StatefulWidget {
  const _RunDust({required this.speed});

  final double speed;

  @override
  State<_RunDust> createState() => _RunDustState();
}

class _RunDustState extends State<_RunDust>
    with SingleTickerProviderStateMixin {
  static const _puffW = 46.0;
  static const _baseDuration = Duration(milliseconds: 900);

  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _applySpeed();
  }

  @override
  void didUpdateWidget(covariant _RunDust old) {
    super.didUpdateWidget(old);
    if (widget.speed != old.speed) _applySpeed();
  }

  void _applySpeed() {
    if (widget.speed <= 0) {
      _c.stop();
      return;
    }
    _c.duration = _baseDuration * (1 / widget.speed);
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 멈춰 있으면 먼지도 안 난다.
    if (widget.speed <= 0) return const SizedBox.shrink();

    return SizedBox(
      width: _puffW * 2.2,
      height: _puffW * 54 / 102 + 10,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < 3; i++)
              () {
                final t = (_c.value + i / 3) % 1.0;
                return Positioned(
                  // right가 커질수록 왼쪽 = 달려가는 방향 반대로 밀려난다.
                  right: t * _puffW * 1.3,
                  bottom: t * 6,
                  child: Opacity(
                    opacity: (1 - t) * 0.9,
                    child: Transform.scale(
                      scale: 0.6 + t * 0.6,
                      child: Image.asset(
                        'assets/images/dog_run_dust.png',
                        width: _puffW,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                );
              }(),
          ],
        ),
      ),
    );
  }
}

/// 하루 상한(15,000보) 대비 진행 게이지. 눈금: 3천/6천/9천/1만2천/1만5천.
class _GoalGauge extends StatelessWidget {
  const _GoalGauge({required this.steps});

  /// 오늘 누적 걸음 수.
  final int steps;

  static const _ticks = [3000, 6000, 9000, 12000, 15000];

  @override
  Widget build(BuildContext context) {
    final value = (steps / WalkMath.dailyMaxSteps).clamp(0.0, 1.0);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 6,
            color: const Color(0xFFECE3D8),
            child: Align(
              alignment: Alignment.centerLeft,
              // 값이 갱신될 때마다 툭 끊기지 않고 부드럽게 차오르게 한다.
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, t, child) => FractionallySizedBox(
                  widthFactor: t,
                  heightFactor: 1,
                  child: child,
                ),
                child: const ColoredBox(color: Color(0xFFFD9448)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final t in _ticks)
              Text(
                _comma(t),
                style: AppText.body(
                  family: 'Pretendard',
                  size: 8,
                  weight: FontWeight.w500,
                  color: _statLabel,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 배경 위에 얹는 반투명 흰 칩(날씨·위치).
class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.text, this.asset});

  /// 픽셀 아이콘이 없는 날씨를 위한 이모지 폴백.
  final String icon;

  /// 있으면 이모지 대신 이 픽셀 아이콘을 쓴다.
  final String? asset;

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset case final path?)
            Image.asset(
              path,
              width: 16,
              height: 16,
              filterQuality: FilterQuality.none,
            )
          else
            Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppText.body(size: 13, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 3단계 — 산책 결과
// ══════════════════════════════════════════════
class _ResultBody extends ConsumerWidget {
  const _ResultBody({required this.session, required this.rewardedPaws});

  final WalkSession session;
  final int rewardedPaws;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = _hPad(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 40, pad, 24),
      children: [
        // 제목 양옆 반짝임. 큰 쪽이 왼쪽, 작은 쪽이 오른쪽 위.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Image.asset(
                'assets/icons/sparkle_lg.png',
                width: 18,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '수고했어요!',
              textAlign: TextAlign.center,
              style: AppText.pixel(size: 30, color: const Color(0xFF573A20)),
            ),
            const SizedBox(width: 10),
            Image.asset(
              'assets/icons/sparkle_sm.png',
              width: 14,
              filterQuality: FilterQuality.none,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '오늘도 건강한 하루를 보냈어요',
          textAlign: TextAlign.center,
          style: AppText.body(size: 14, weight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Image.asset(
          'assets/images/walk_result.png',
          height: 190,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
        const SizedBox(height: 26),
        const _SectionTitle('산책결과'),
        const SizedBox(height: 10),
        _StatTriple(
          items: [
            (
              // 걸음 센서가 있으면 실측값, 없으면 거리에서 환산한 추정치.
              icon: const _StatIcon(_StatIcon.steps),
              value: _comma(session.steps),
              label: '걸음 수',
              color: _stepsOrange,
            ),
            (
              icon: const _StatIcon(_StatIcon.distance),
              value: '${session.km.toStringAsFixed(1)}km',
              label: '산책거리',
              color: _distanceGreen,
            ),
            (
              icon: const _StatIcon(_StatIcon.paw),
              value: '+${_comma(rewardedPaws)}',
              label: '획득 발자국',
              color: _stepsOrange,
            ),
          ],
        ),
        // 발자국이 0이면 왜 0인지 알려준다(조용히 0이면 버그처럼 보인다).
        if (rewardedPaws == 0) ...[
          const SizedBox(height: 10),
          Text(
            session.steps >= WalkMath.rewardMinSteps
                ? '오늘 받을 수 있는 발자국을 모두 받았어요'
                : '${_comma(WalkMath.rewardMinSteps)}보 이상 걸어야 '
                      '발자국을 받을 수 있어요',
            textAlign: TextAlign.center,
            style: AppText.body(size: 12, color: AppColors.subtle),
          ),
        ],
        const SizedBox(height: 22),
        _WideButton(
          label: '발자국 사용하기',
          background: const Color(0xFFFD8B3E),
          foreground: const Color(0xFFFFFEFD),
          height: 52,
          trailing: Image.asset(
            'assets/icons/paw_dark.png',
            width: 18,
            height: 18,
            filterQuality: FilterQuality.none,
          ),
          // 발자국은 미니룸 아이템을 사는 화폐 → 미니룸 탭으로.
          // 산책은 여기서 끝났으니 상태도 초기화해, 산책 탭에 다시 오면
          // 결과 화면이 아니라 첫 화면이 나오게 한다.
          onTap: () {
            ref.read(walkProvider.notifier).reset();
            ref.read(storeTabRequestProvider.notifier).request(
              StoreTab.miniroom,
            );
            context.go('/store');
          },
        ),
        const SizedBox(height: 12),
        _WideButton(
          label: '다시 산책하기',
          background: const Color(0xFFFDEFDE),
          foreground: const Color(0xFF201E1C),
          height: 52,
          onTap: () => ref.read(walkProvider.notifier).reset(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// 공용 조각
// ══════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppText.body(
      family: 'Pretendard',
      size: 16,
      weight: FontWeight.w700,
      color: _sectionInk,
    ),
  );
}

/// 흰 카드 공통 껍데기. (배경 #fff / 1px #F0E8DE / radius 5)
class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _cardLine),
      borderRadius: BorderRadius.circular(5),
    ),
    child: child,
  );
}

/// 아이콘 + 큰 숫자 + 라벨 3칸짜리 기록 카드.
/// 가운데 칸만 좌우에 0.5px 구분선을 둬 세 칸이 나뉜다.
class _StatTriple extends StatelessWidget {
  const _StatTriple({required this.items});

  final List<({Widget icon, String value, String label, Color color})> items;

  @override
  Widget build(BuildContext context) {
    // 가운데 칸(산책거리 등) 좌우 구분선: #000 10%, 0.5px.
    const side = BorderSide(color: Color(0x1A000000), width: 0.5);
    return _Panel(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == 1
                        ? const Border(left: side, right: side)
                        : null,
                  ),
                  child: _MiniStat(
                    icon: items[i].icon,
                    value: items[i].value,
                    label: items[i].label,
                    color: items[i].color,
                    valueSize: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.valueSize = 18,
  });

  final Widget icon;
  final String value;
  final String label;
  final Color color;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(height: 8),
        // 값이 길어도(예: 10,000) 칸을 넘치지 않게 한 덩어리로 줄인다.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppText.body(
              size: valueSize,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppText.body(
            family: 'Pretendard',
            size: 13,
            weight: FontWeight.w500,
            color: _statLabel,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
    width: 0.5,
    height: 44,
    color: const Color(0x1A000000), // #000 10%
  );
}

/// 기록 카드의 픽셀 아이콘. 시간만 전용 에셋이 없어 머티리얼 아이콘으로 대체한다.
class _StatIcon extends StatelessWidget {
  const _StatIcon(this.asset);

  static const steps = 'assets/icons/walk_steps.png'; // 걸음 수(추정)
  static const paw = 'assets/icons/walk_paw.png'; // 획득 발자국
  static const distance = 'assets/icons/walk_distance.png'; // 산책거리
  static const timer = ''; // 시간 (픽셀 에셋 대기)

  final String asset;

  @override
  Widget build(BuildContext context) => asset.isEmpty
      ? const Icon(Icons.timer_outlined, size: 26, color: _stepsOrange)
      : Image.asset(
          asset,
          width: 28,
          height: 28,
          filterQuality: FilterQuality.none,
        );
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.height = 56,
    this.radius = 5,
    this.enabled = true,
    this.trailing,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final double height;
  final double radius;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppText.body(
                size: 16,
                weight: FontWeight.w700,
                color: foreground,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 발자국 아이콘. [white]면 버튼 위에 얹도록 흰색으로 틴트한다.
class _PawIcon extends StatelessWidget {
  const _PawIcon({required this.size, this.white = false, this.opacity = 1});

  final double size;
  final bool white;

  /// 버튼 비활성 상태에서 글자와 같이 흐려지도록.
  final double opacity;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Image.asset(
      'assets/icons/walk_paw.png',
      width: size,
      height: size,
      color: white ? Colors.white : null,
      colorBlendMode: white ? BlendMode.srcIn : null,
      filterQuality: FilterQuality.none,
    ),
  );
}

String _comma(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
