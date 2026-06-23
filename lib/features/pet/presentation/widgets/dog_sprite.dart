import 'package:flutter/material.dart';

/// 강아지 스프라이트 프레임 모음.
///
/// 나중에 모션 프레임 이미지를 받으면 아래 리스트에 경로만 추가하세요.
/// (예: idle에 'assets/images/dog_idle_1.png', 'assets/images/dog_idle_2.png' ...)
/// 추가하는 순서대로 [DogSprite]가 자동으로 순환 재생합니다.
class DogFrames {
  DogFrames._();

  /// 가만히 서 있을 때 (idle) 프레임. 현재는 기본 1장.
  static const List<String> idle = [
    'assets/images/dog.png',
  ];

  /// 걸을 때 (walk) 프레임. 현재는 idle과 동일(추후 교체).
  static const List<String> walk = [
    'assets/images/dog.png',
  ];
}

/// 프레임 리스트를 [fps]로 순환 재생하는 스프라이트 위젯.
///
/// - 프레임이 2장 이상이면 프레임 애니메이션 재생.
/// - 프레임이 1장뿐이면 [breatheWhenSingle]에 따라 가벼운 "숨쉬기" 모션으로 폴백.
/// - 픽셀이 또렷하도록 [FilterQuality.none]로 렌더.
class DogSprite extends StatefulWidget {
  const DogSprite({
    super.key,
    required this.frames,
    this.size = 120,
    this.fps = 6,
    this.flip = false,
    this.breatheWhenSingle = true,
  });

  final List<String> frames;
  final double size;
  final double fps;
  final bool flip;
  final bool breatheWhenSingle;

  @override
  State<DogSprite> createState() => _DogSpriteState();
}

class _DogSpriteState extends State<DogSprite>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  Duration get _loopDuration {
    final count = widget.frames.length;
    if (count > 1) {
      final ms = (count / widget.fps * 1000).round();
      return Duration(milliseconds: ms.clamp(120, 100000));
    }
    // 단일 프레임 숨쉬기 1주기.
    return const Duration(milliseconds: 1600);
  }

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _loopDuration)..repeat();
  }

  @override
  void didUpdateWidget(covariant DogSprite old) {
    super.didUpdateWidget(old);
    if (old.frames.length != widget.frames.length || old.fps != widget.fps) {
      _c
        ..duration = _loopDuration
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
    final multiFrame = widget.frames.length > 1;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        Widget img;
        double scaleY = 1.0;
        double dy = 0.0;

        if (multiFrame) {
          final idx =
              (t * widget.frames.length).floor() % widget.frames.length;
          img = _frame(widget.frames[idx]);
        } else {
          img = _frame(widget.frames.first);
          if (widget.breatheWhenSingle) {
            // 0→1→0 사인 곡선으로 살짝 세로 신축 + 미세 상하.
            final s = (1 - (2 * t - 1).abs()); // 삼각파
            scaleY = 1.0 + 0.035 * s;
            dy = -2.0 * s;
          }
        }

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..scaleByDouble(widget.flip ? -1.0 : 1.0, scaleY, 1.0, 1.0),
            child: img,
          ),
        );
      },
    );
  }

  Widget _frame(String path) => Image.asset(
        path,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
      );
}
