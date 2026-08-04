import 'package:flutter/material.dart';

/// 여러 배경을 가로로 이어 붙여 흘려보내는 스크롤 배경(끝나면 처음으로 이음).
///
/// 8.15초 게임에서 배경 16장을 순서대로 이어 달리는 느낌을 준다.
class LoopingScenery extends StatefulWidget {
  const LoopingScenery({
    super.key,
    required this.images,
    this.aspect = 1236 / 1665,
    this.speed = 1.0,
  });

  /// 순서대로 이어 붙일 asset 경로들(마지막 다음은 처음으로 이어짐).
  final List<String> images;

  /// 그림 한 장의 가로/세로 비율.
  final double aspect;

  /// 흐르는 배속(0이면 정지).
  final double speed;

  @override
  State<LoopingScenery> createState() => _LoopingSceneryState();
}

class _LoopingSceneryState extends State<LoopingScenery>
    with SingleTickerProviderStateMixin {
  // 그림 한 장이 지나가는 기준 시간(배속 1.0).
  static const _perTile = Duration(seconds: 7);

  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(covariant LoopingScenery old) {
    super.didUpdateWidget(old);
    if (widget.speed != old.speed) _apply();
  }

  void _apply() {
    if (widget.speed <= 0) {
      _c.stop(); // 멈춘 위치(_c.value) 유지 → 다시 시작하면 그 배경에서 이어짐.
      return;
    }
    // 전체 한 바퀴(모든 그림) 시간 = 장수 × 기준시간 ÷ 배속.
    _c.duration = _perTile * (widget.images.length / widget.speed);
    // repeat()는 현재 위상(_c.value)에서 이어서 반복한다(처음으로 리셋 안 함).
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images;
    if (imgs.isEmpty) return const SizedBox.shrink();
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) {
          final h = box.maxHeight;
          final tileW = h * widget.aspect;
          if (tileW <= 0) return const SizedBox.shrink();
          final loopW = imgs.length * tileW; // 한 바퀴 거리
          return AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.translate(
              offset: Offset(-_c.value * loopW, 0),
              child: child,
            ),
            // 이미지들 + 이음매용으로 화면을 덮을 만큼 앞쪽 몇 장을 더 붙인다.
            child: OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < imgs.length + 3; i++)
                    Image.asset(
                      imgs[i % imgs.length],
                      width: tileW,
                      height: h,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
