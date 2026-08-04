import 'package:flutter/material.dart';

/// 달릴 때 발밑에 흩날리는 먼지. 산책 화면과 미니게임이 공유한다.
///
/// 컨트롤러는 항상 반복 재생하고, [speed] 는 표시 여부(0이면 숨김)와 흩날리는
/// 빠르기(주기)만 조정한다. 매 프레임 재시작하지 않으므로 먼지가 멈춰 보이지 않는다.
class RunDust extends StatefulWidget {
  const RunDust({super.key, this.speed = 1.0, this.puffWidth = 46.0});

  /// 0이면 숨김. 클수록 조금 더 빠르게 흩날린다.
  final double speed;

  /// 먼지 한 덩이의 폭.
  final double puffWidth;

  @override
  State<RunDust> createState() => _RunDustState();
}

class _RunDustState extends State<RunDust> with SingleTickerProviderStateMixin {
  static const _baseDuration = Duration(milliseconds: 900);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _baseDuration,
  )..repeat();

  double _appliedSpeed = 1;

  @override
  void didUpdateWidget(covariant RunDust old) {
    super.didUpdateWidget(old);
    // 속도가 눈에 띄게 바뀔 때만 주기 조정(미세 변화로 재시작하지 않는다).
    final s = widget.speed.clamp(0.6, 4.5);
    if ((s - _appliedSpeed).abs() > 0.3) {
      _appliedSpeed = s.toDouble();
      _c
        ..duration = _baseDuration * (1 / s)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.speed <= 0) return const SizedBox.shrink();
    final puffW = widget.puffWidth;
    return SizedBox(
      width: puffW * 2.2,
      height: puffW * 54 / 102 + 10,
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
                  right: t * puffW * 1.3,
                  bottom: t * 6,
                  child: Opacity(
                    opacity: (1 - t) * 0.9,
                    child: Transform.scale(
                      scale: 0.6 + t * 0.6,
                      child: Image.asset(
                        'assets/images/dog_run_dust.png',
                        width: puffW,
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
