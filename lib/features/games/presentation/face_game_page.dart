import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';
import '../../pet/application/pet_providers.dart';

double _hPad(BuildContext context) => DesignScale.scaled(context, 28);

const _ink = Color(0xFF2D2D2D);
const _coral = Color(0xFFF4845F);
const _stroke = Color(0xFF7F542F); // 픽셀 텍스트 외곽선

// ── 강아지 배치(플레이 영역 대비) — 조정하려면 이 값만 바꾸면 된다 ──
const _dogTopFrac = 0.57;
const _dogHeightFrac = 0.27;
const _dogAspect = 176 / 245;

class _Slot {
  const _Slot(this.asset, this.fx, this.fy, this.sizeFrac);
  final String asset;
  final double fx;
  final double fy;
  final double sizeFrac;
}

// 크기(sizeFrac)는 시안(몸 176px 대비) 비율: 눈 13·볼 18·코입 29px.
//
// 가로는 얼굴 중심 기준 좌우 대칭. 온보딩 미리보기(`PartsDog`)와 같은 값이어야
// 하니, 한쪽을 고치면 다른 쪽도 같이 맞출 것.
//
// **캔버스 한가운데(0.5)가 아니다** — dog_blank.png의 머리가 살짝 오른쪽에
// 그려져 있어서(실루엣 무게중심 0.5025~0.5035), 0.5에 맞추면 파츠가 얼굴보다
// 왼쪽으로 밀려 보인다. 원화의 눈 중점 0.5057·볼 중점 0.5068에 맞춘 값이다.
const _faceCx = 0.506;
const _eyeDx = 0.1307; // 눈 실측 간격의 절반
const _cheekDx = 0.201; // 볼 간격의 절반

// snout.png의 투명 여백을 잘라내(87x84 → 81x79) 앵커가 곧 그림 중심이 된다.
// 여백이 빠진 만큼 그림이 커 보이므로 표시 크기를 0.165 → 0.165×81/87로 줄였다.
const _snoutSize = 0.15362;

const _slots = <_Slot>[
  _Slot('assets/images/games/parts/eye_l.png', _faceCx - _eyeDx, 0.30, 0.08),
  _Slot('assets/images/games/parts/eye_r.png', _faceCx + _eyeDx, 0.30, 0.08),
  _Slot('assets/images/games/parts/cheek_l.png', _faceCx - _cheekDx, 0.415,
      0.102),
  _Slot('assets/images/games/parts/cheek_r.png', _faceCx + _cheekDx, 0.415,
      0.102),
  _Slot('assets/images/games/parts/snout.png', _faceCx, 0.4077, _snoutSize),
];

double _slotY(_Slot s) => _dogTopFrac + s.fy * _dogHeightFrac;

const _fallTop = 0.03;
// 정확도(강아지 높이 대비): 이 안이면 100%(퍼펙트 존), 이 밖이면 0%.
const _perfect = 0.035; // 타이밍 잘 맞추면(약 1프레임 이내) 100%
const _tolerance = 0.14; // 이만큼 벗어나면 0%
const _spawnWindow = 8.15;

enum _Phase { intro, countdown, playing, done }

class _Part {
  _Part(this.slot, this.spawn, this.dur);
  final _Slot slot;
  final double spawn;
  final double dur;
  bool locked = false;
  double lockedY = 0;
  double acc = 0;
}

/// 강아지 얼굴 맞추기: 8.15초 안에 랜덤 등장·낙하하는 파츠를 STOP으로 제자리에 놓는다.
class FaceGamePage extends ConsumerStatefulWidget {
  const FaceGamePage({super.key});

  @override
  ConsumerState<FaceGamePage> createState() => _FaceGamePageState();
}

class _FaceGamePageState extends ConsumerState<FaceGamePage> {
  final _rng = Random();
  _Phase _phase = _Phase.intro;

  int _count = 3;
  Timer? _countTimer;

  late List<_Part> _parts;
  double _clock = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _countTimer?.cancel();
    _ticker?.cancel();
    _keyFocus.dispose();
    super.dispose();
  }

  /// 엔터로 조작하기 위한 포커스(키보드가 있는 웹·데스크톱에서만 의미 있다).
  final _keyFocus = FocusNode();

  /// 지금 단계에서 STOP 버튼이 하는 일과 똑같이 동작한다.
  /// 카운트다운 중에는 버튼이 비활성이라 엔터도 먹지 않는다.
  void _primaryAction() {
    switch (_phase) {
      case _Phase.intro:
        _startCountdown();
      case _Phase.countdown:
        break;
      case _Phase.playing:
        _stopLowest();
      case _Phase.done:
        _restart();
    }
  }

  void _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return; // 누를 때 한 번만(꾹 누르면 반복 방지)
    if (e.logicalKey == LogicalKeyboardKey.enter ||
        e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _primaryAction();
    }
  }

  double _fallY(double p) => _fallTop + p.clamp(0.0, 1.0) * (0.95 - _fallTop);

  int get _lockedCount => _parts.where((p) => p.locked).length;

  double get _avgAcc {
    final done = _parts.where((p) => p.locked).toList();
    if (done.isEmpty) return 0;
    return done.map((e) => e.acc).reduce((a, b) => a + b) / done.length;
  }

  void _startCountdown() {
    setState(() {
      _phase = _Phase.countdown;
      _count = 3;
      _clock = 0;
      // 등장 시각: 8.15초 안에 고르게 퍼지되 파츠 사이 최소 0.5초 간격.
      // 여유시간(8.15 - 4*0.5)만 랜덤으로 나누고, 정렬 후 i*0.5씩 더해 간격을 보장.
      const n = 5; // 파츠 수(_slots.length)
      const minGap = 0.5;
      final free = _spawnWindow - (n - 1) * minGap;
      final points = List.generate(n, (_) => _rng.nextDouble() * free)..sort();
      final order = List.generate(n, (i) => i)..shuffle(_rng);
      _parts = [
        for (int i = 0; i < n; i++)
          _Part(
            _slots[order[i]],
            points[i] + i * minGap, // 앞 파츠와 최소 0.5초 간격
            2.8 + _rng.nextDouble() * 1.8, // 낙하 시간 2.8~4.6초(속도 절반)
          ),
      ];
    });
    _countTimer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) return;
      if (_count <= 0) {
        t.cancel();
        _beginPlay();
      } else {
        setState(() => _count--);
      }
    });
  }

  void _beginPlay() {
    setState(() => _phase = _Phase.playing);
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    _clock += 16 / 1000;
    for (final p in _parts) {
      if (!p.locked && _clock >= p.spawn) {
        final prog = (_clock - p.spawn) / p.dur;
        if (prog >= 1) _lockPart(p, 1);
      }
    }
    setState(() {});
    if (_parts.every((p) => p.locked)) _finish();
  }

  void _lockPart(_Part p, double prog) {
    if (p.locked) return;
    final y = _fallY(prog);
    // 오차를 강아지 높이 기준으로 정규화(작은 강아지에서도 엄격하게).
    // 퍼펙트 존(_perfect) 안이면 100%, _tolerance 밖이면 0%, 사이는 선형.
    final errInDog = (y - _slotY(p.slot)).abs() / _dogHeightFrac;
    p
      ..locked = true
      ..lockedY = y
      ..acc = (1 - (errInDog - _perfect) / (_tolerance - _perfect))
          .clamp(0.0, 1.0);
  }

  void _stopLowest() {
    _Part? lowest;
    double maxY = -1;
    for (final p in _parts) {
      if (p.locked || _clock < p.spawn) continue;
      final prog = (_clock - p.spawn) / p.dur;
      if (prog >= 1) continue;
      final y = _fallY(prog);
      if (y > maxY) {
        maxY = y;
        lowest = p;
      }
    }
    if (lowest == null) return;
    final p = lowest;
    setState(() => _lockPart(p, (_clock - p.spawn) / p.dur));
  }

  void _finish() {
    _ticker?.cancel();
    setState(() => _phase = _Phase.done);
  }

  void _restart() => setState(() => _phase = _Phase.intro);

  String get _resultMsg {
    final p = _avgAcc * 100;
    if (p >= 99.9) return '🇰🇷 성공! 완벽해요 🇰🇷'; // 100%
    if (p >= 95) return '완벽에 가까워요! 🎯';
    if (p >= 80) return '훌륭해요! 👏';
    if (p >= 60) return '좋아요! 🐶';
    return '다시 도전해봐요! 💪';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return KeyboardListener(
      focusNode: _keyFocus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F2),
        body: Column(
          children: [
            _header(context, topPad),
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(_hPad(context), 14, _hPad(context), 20),
                child: _playArea(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, double topPad) => Container(
        color: AppColors.primary,
        padding: EdgeInsets.only(
            top: topPad + 62,
            left: _hPad(context),
            right: _hPad(context),
            bottom: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/games'),
              behavior: HitTestBehavior.opaque,
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('${ref.watch(petProvider)?.name ?? '세미'} 얼굴 맞추기',
                style: AppText.body(
                    family: 'Pretendard',
                    size: 21,
                    color: Colors.white,
                    weight: FontWeight.w800)),
          ],
        ),
      );

  Widget _playArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final playing = _phase == _Phase.playing;
          final counting = _phase == _Phase.countdown;

          final dogH = h * _dogHeightFrac;
          final dogW = dogH * _dogAspect;
          final dogLeft = w / 2 - dogW / 2;
          final dogTop = h * _dogTopFrac;
          double slotXpx(_Slot s) => dogLeft + s.fx * dogW;

          Widget partAt(_Slot s, double yFrac,
              {double scale = 1.0, double opacity = 1.0}) {
            final size = dogW * s.sizeFrac * scale;
            Widget img = Image.asset(s.asset,
                filterQuality: FilterQuality.none, fit: BoxFit.contain);
            if (opacity < 1) img = Opacity(opacity: opacity, child: img);
            return Positioned(
              left: slotXpx(s) - size / 2,
              top: yFrac * h - size / 2,
              width: size,
              height: size,
              child: img,
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 방 배경(위아래 안 잘리게 + 벽색으로 양옆 채움)
              const ColoredBox(color: Color(0xFFF6E6CF)),
              Image.asset('assets/images/games/face/room.webp',
                  fit: BoxFit.fitHeight,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              // 얼굴 없는 강아지 베이스(인트로·게임 중 동일).
              Positioned(
                left: dogLeft,
                top: dogTop,
                width: dogW,
                height: dogH,
                child: Image.asset('assets/images/games/face/dog_blank.png',
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
              // 인트로: 완성 미리보기 — 파츠를 제자리에 크게(게임과 동일 크기).
              if (_phase == _Phase.intro)
                for (final s in _slots) partAt(s, _slotY(s), scale: 1.4),
              // 타겟 마커(플레이 중에만): 놓아야 할 파츠를 흐리게 깔아둔다.
              // 떨어지는 파츠와 같은 크기·위치라 겹치면 딱 맞는 순간이 눈에 보인다.
              // 놓은 뒤에도 그대로 두고 실제 파츠가 그 위에 겹쳐 그려진다.
              if (playing || counting)
                for (final s in _slots)
                  partAt(s, _slotY(s), scale: 1.4, opacity: 0.25),
              // 놓인 파츠(떨어질 때와 같은 크기로 — 작아지지 않게).
              if (playing || _phase == _Phase.done)
                for (final p in _parts.where((p) => p.locked))
                  partAt(p.slot, p.lockedY, scale: 1.4),
              // 떨어지는 파츠(놓기 전엔 크게).
              if (playing)
                for (final p
                    in _parts.where((p) => !p.locked && _clock >= p.spawn))
                  partAt(p.slot, _fallY((_clock - p.spawn) / p.dur), scale: 1.4),

              // ── 인트로: 강아지 위에 말풍선(크게), 아래에 MINI GAME ──
              if (_phase == _Phase.intro) ...[
                // 말풍선(강아지 위, MINI GAME과 대칭 간격 0.05h).
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: h * (1 - _dogTopFrac + 0.05), // 강아지 위쪽에 간격
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Image.asset(
                        'assets/images/games/face/bubble.webp',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                // MINI GAME(강아지 아래, 대칭 간격 0.05h).
                Positioned(
                  left: 0,
                  right: 0,
                  top: h * (_dogTopFrac + _dogHeightFrac + 0.05),
                  child: Center(
                    child: _pixelOutlined('MINI GAME',
                        size: 72,
                        fill: const Color(0xFF9E6941),
                        strokeW: 4.76),
                  ),
                ),
                // 아무 곳이나 탭하면 시작.
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _startCountdown,
                    behavior: HitTestBehavior.opaque,
                  ),
                ),
              ],

              // ── 카운트다운 / START ──
              if (counting)
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _pixelOutlined(_count == 0 ? 'START!' : '$_count',
                        size: 96,
                        fill: const Color(0xFFF9F1E3),
                        strokeW: 6),
                  ),
                ),

              // ── 진행 상태(플레이 중) ──
              if (playing)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('$_lockedCount / ${_slots.length}',
                          style: AppText.body(
                              size: 13,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ),

              // ── 결과(상단 중앙·크게) ──
              if (_phase == _Phase.done)
                Align(
                  alignment: const Alignment(0, -0.5), // 강아지 위·화면 상단 중앙
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 52, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${(_avgAcc * 100).toStringAsFixed(1)}%',
                            style: AppText.pixel(size: 78, color: _coral)),
                        const SizedBox(height: 12),
                        Text(_resultMsg,
                            style: AppText.body(
                                size: 28,
                                weight: FontWeight.w800,
                                color: _ink)),
                      ],
                    ),
                  ),
                ),

              // ── 컨트롤(STOP 등) — 인트로 MINI GAME과 같은 높이 ──
              Positioned(
                left: 0,
                right: 0,
                top: h * (_dogTopFrac + _dogHeightFrac + 0.05),
                child: Center(child: _control()),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 하단 STOP/시작/다시하기 — 씬 안쪽에 배치.
  Widget _control() {
    switch (_phase) {
      case _Phase.intro:
        return const SizedBox.shrink(); // 시작은 MINI GAME 글자 탭으로
      case _Phase.countdown:
        return _stopButton(active: false, onTap: null); // 회색(비활성)
      case _Phase.playing:
        return _stopButton(active: true, onTap: _stopLowest); // 주황(활성)
      case _Phase.done:
        return _pill('다시하기', _coral, _restart);
    }
  }

  Widget _stopButton({required bool active, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Image.asset(
        active
            ? 'assets/images/games/face/stop_on.png'
            : 'assets/images/games/face/stop_off.png',
        width: 132,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _pill(
            'STOP', active ? _coral : const Color(0xFF9E9E9E), onTap ?? () {}),
      ),
    );
  }

  Widget _pill(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: AppText.body(
                size: 22, weight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }

  /// LanaPixel 외곽선 텍스트(스트로크 + 채움).
  Widget _pixelOutlined(String s,
      {required double size, required Color fill, required double strokeW}) {
    final strokeStyle = TextStyle(
      fontFamily: AppText.pixelFamily,
      fontSize: size,
      height: 1.0,
      letterSpacing: 0.5,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeJoin = StrokeJoin.round
        ..color = _stroke,
    );
    return Stack(
      children: [
        Text(s, textAlign: TextAlign.center, style: strokeStyle),
        Text(s,
            textAlign: TextAlign.center,
            style: AppText.pixel(size: size, height: 1.0, color: fill)),
      ],
    );
  }
}

