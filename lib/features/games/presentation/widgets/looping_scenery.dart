import 'package:flutter/material.dart';

/// 여러 배경을 가로로 이어 붙여 흘려보내는 스크롤 배경(끝나면 처음으로 이음).
///
/// 8.15초 게임에서 달리는 느낌을 준다.
///
/// **한 칸 걸러 좌우로 뒤집어 붙인다(짝수=원본, 홀수=미러).** 같은 그림을
/// 그냥 이어 붙이면 오른쪽 끝과 왼쪽 끝이 안 맞아 이음매에 세로 경계선이
/// 보인다. 뒤집으면 맞닿는 두 가장자리가 같은 픽셀이라 선이 사라진다.
/// 그래서 한 바퀴 길이가 그림 장수가 아니라 [_periodTiles] 칸이 된다.
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

  /// 한 바퀴에 들어가는 칸 수.
  ///
  /// 칸마다 원본·미러가 번갈아 나오므로, 장수가 홀수면 두 바퀴를 돌아야
  /// 원래 배치로 돌아온다(예: 1장 → 원본·미러 2칸이 한 바퀴).
  int get _periodTiles {
    final n = widget.images.length;
    return n.isEven ? n : n * 2;
  }

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
    // 전체 한 바퀴 시간 = 한 바퀴 칸수 × 기준시간 ÷ 배속.
    // (칸당 속도는 장수·미러 여부와 무관하게 일정하다.)
    _c.duration = _perTile * (_periodTiles / widget.speed);
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
          final loopW = _periodTiles * tileW; // 한 바퀴 거리
          return AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.translate(
              offset: Offset(-_c.value * loopW, 0),
              child: child,
            ),
            // 한 바퀴 + 이음매용으로 화면을 덮을 만큼 앞쪽 몇 칸을 더 붙인다.
            child: OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < _periodTiles + 3; i++)
                    _tile(imgs[i % imgs.length], tileW, h, mirrored: i.isOdd),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 한 칸. [mirrored]면 좌우로 뒤집어 이음매를 없앤다.
  Widget _tile(String asset, double w, double h, {required bool mirrored}) {
    final img = Image.asset(
      asset,
      width: w,
      height: h,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
    );
    if (!mirrored) return img;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
      child: img,
    );
  }
}
