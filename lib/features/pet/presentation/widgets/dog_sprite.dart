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
    'assets/images/dog.webp',
  ];

  /// 걸을 때 (walk) 프레임. 앞다리/뒷다리 위치가 다른 2장을 번갈아 재생.
  static const List<String> walk = [
    'assets/images/dog_walk_1.webp',
    'assets/images/dog_walk_2.png',
  ];

  /// 산책 화면에서 달릴 때 (run) 프레임.
  /// 두 장 모두 발이 캔버스 아래에 맞춰 정렬돼 있어 재생 중 위아래로 튀지 않는다.
  static const List<String> run = [
    'assets/images/dog_run_1.png',
    'assets/images/dog_run_2.png',
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
    this.tint,
    this.overlayBuilder,
  });

  final List<String> frames;
  final double size;
  final double fps;
  final bool flip;
  final bool breatheWhenSingle;

  /// 프레임 그림에만 곱해(modulate) 입힐 색. 위에 얹는 [overlayBuilder]에는
  /// 적용되지 않는다(얼굴 파츠까지 물들이지 않으려고 여기서 나눠 칠한다).
  final Color? tint;

  /// 지금 그리는 프레임 번호를 받아 그 위에 얹을 것들을 돌려준다.
  /// 프레임과 같은 컨트롤러를 쓰므로 몸통과 항상 붙어 움직인다.
  final List<Widget> Function(int frameIndex)? overlayBuilder;

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
        int idx = 0;

        if (multiFrame) {
          idx = (t * widget.frames.length).floor() % widget.frames.length;
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

        // 얼굴 파츠는 몸통 위에 같은 프레임 기준으로 얹는다.
        final overlay = widget.overlayBuilder?.call(idx) ?? const <Widget>[];
        if (overlay.isNotEmpty) {
          img = SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [Positioned.fill(child: img), ...overlay],
            ),
          );
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

  Widget _frame(String path) {
    final Widget img = Image.asset(
      path,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
    );
    final tint = widget.tint;
    if (tint == null) return img;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
      child: img,
    );
  }
}
