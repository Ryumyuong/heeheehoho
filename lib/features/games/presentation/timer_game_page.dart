import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';
import '../../pet/presentation/widgets/running_dog.dart';
import '../../walk/presentation/widgets/run_dust.dart';
import 'widgets/looping_scenery.dart';

double _hPad(BuildContext context) => DesignScale.scaled(context, 28);

const _targetMs = 8150; // 목표 8.15초

enum _Phase { ready, running, stopped }

/// 8.15초 맞추기: 달리는 강아지를 8.15초에 최대한 가깝게 멈춘다.
class TimerGamePage extends StatefulWidget {
  const TimerGamePage({super.key});

  @override
  State<TimerGamePage> createState() => _TimerGamePageState();
}

class _TimerGamePageState extends State<TimerGamePage> {
  final _watch = Stopwatch();
  Timer? _ticker;
  _Phase _phase = _Phase.ready;
  int _elapsedMs = 0;

  // 배경 16장을 순서대로 이어 붙인다.
  static const _bg16 = [
    'assets/images/games/bg/bg_01.webp',
    'assets/images/games/bg/bg_02.webp',
    'assets/images/games/bg/bg_03.webp',
    'assets/images/games/bg/bg_04.webp',
    'assets/images/games/bg/bg_05.webp',
    'assets/images/games/bg/bg_06.webp',
    'assets/images/games/bg/bg_07.webp',
    'assets/images/games/bg/bg_08.webp',
    'assets/images/games/bg/bg_09.webp',
    'assets/images/games/bg/bg_10.webp',
    'assets/images/games/bg/bg_11.webp',
    'assets/images/games/bg/bg_12.webp',
    'assets/images/games/bg/bg_13.webp',
    'assets/images/games/bg/bg_14.webp',
    'assets/images/games/bg/bg_15.webp',
    'assets/images/games/bg/bg_16.webp',
  ];

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.running;
      _elapsedMs = 0;
      // 배경은 시작 때 바꾸지 않는다(현재 배경 유지). 다시하기 때만 바뀐다.
    });
    _watch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs = _watch.elapsedMilliseconds);
    });
  }

  void _stop() {
    _watch.stop();
    _ticker?.cancel();
    setState(() {
      _elapsedMs = _watch.elapsedMilliseconds;
      _phase = _Phase.stopped;
    });
  }

  void _reset() {
    setState(() {
      _phase = _Phase.ready;
      _elapsedMs = 0;
    });
  }

  int get _diff => (_elapsedMs - _targetMs).abs();

  String get _resultMsg {
    if (_diff <= 5) return '🇰🇷 성공! 대단해요 🇰🇷'; // 8.15초로 표시(오차 0.00초)
    if (_diff <= 100) return '대박! 아주 근접했어요 🔥';
    if (_diff <= 300) return '훌륭해요! 👏';
    if (_diff <= 600) return '아깝다! 조금만 더 🐾';
    return '다시 도전해봐요! 💪';
  }

  Color get _timerColor => _phase == _Phase.running
      ? const Color(0xFFE5352B) // 달리는 중엔 빨강
      : const Color(0xFF2D2D2D); // 멈추면 검정

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final running = _phase == _Phase.running;
    final secs = (_elapsedMs / 1000).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: Column(
        children: [
          // 헤더
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: topPad + 62,
              left: _hPad(context),
              right: _hPad(context),
              bottom: 14,
            ),
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
                Text(
                  '8.15초 맞추기',
                  style: AppText.body(
                    family: 'Pretendard',
                    size: 22,
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // 배경(전체) + 타이머·강아지·버튼·결과를 그 안에 오버레이.
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final h = c.maxHeight;
                final dogSize = h * 0.30; // 얼굴게임 강아지 정도로 크게
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 16장 배경을 이어 붙여 스크롤(달릴 때만).
                    LoopingScenery(images: _bg16, speed: running ? 3.6 : 0),
                    // 달리는 강아지 + 먼지
                    Align(
                      alignment: const Alignment(0, 0.60),
                      child: SizedBox(
                        height: dogSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            if (running)
                              // 뒷발(스프라이트 가로 0.20~0.25 지점) 바로 뒤에서
                              // 피어나 왼쪽으로 흩날리도록. bottom은 발이 닿는 높이.
                              Positioned(
                                bottom: dogSize * 0.10,
                                right: dogSize * 0.78,
                                child: RunDust(
                                  speed: 2.0,
                                  puffWidth: dogSize * 0.42,
                                ),
                              ),
                            running
                                ? RunningDog(
                                    equipped: const [],
                                    furColor: Colors.white,
                                    size: dogSize,
                                    fps: 8,
                                  )
                                : Image.asset(
                                    'assets/images/dog_walk_1.webp',
                                    height: dogSize,
                                    filterQuality: FilterQuality.none,
                                    errorBuilder: (_, __, ___) => const Text(
                                        '🐕', style: TextStyle(fontSize: 64)),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    // 안내 멘트 + 타이머(강아지 위쪽).
                    Align(
                      alignment: const Alignment(0, -0.35),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _pill('🎯 8.15초에 딱 멈추세요',
                              const Color(0xFF5A5A5A), 17),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text('$secs초',
                                style: AppText.pixel(
                                    size: 60, height: 1.0, color: _timerColor)),
                          ),
                        ],
                      ),
                    ),
                    // 결과(배경 안 상단)
                    if (_phase == _Phase.stopped)
                      Positioned(
                        top: 18,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 52, vertical: 40),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_resultMsg,
                                    style: AppText.body(
                                        size: 34,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF2D2D2D))),
                                const SizedBox(height: 10),
                                Text(
                                    '목표까지 ${(_diff / 1000).toStringAsFixed(2)}초',
                                    style: AppText.body(
                                        size: 20,
                                        color: const Color(0xFF888888))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // 버튼(배경 안, 얼굴게임 MINI GAME 정도 높이)
                    Positioned(
                      bottom: h * 0.05,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _ActionButton(
                            phase: _phase,
                            onStart: _start,
                            onStop: _stop,
                            onReset: _reset),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 반투명 흰 알약 라벨.
  Widget _pill(String text, Color color, double size) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: AppText.body(
                size: size, weight: FontWeight.w700, color: color)),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.phase,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });
  final _Phase phase;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final (label, color, onTap) = switch (phase) {
      _Phase.ready => ('시작', const Color(0xFFF4845F), onStart),
      _Phase.running => ('STOP', const Color(0xFFE5352B), onStop),
      _Phase.stopped => ('다시하기', const Color(0xFFF4845F), onReset),
    };
    // 얼굴 맞추기의 '다시하기' 버튼과 같은 알약 모양·크기(그쪽 `_pill` 참고).
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 22,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
