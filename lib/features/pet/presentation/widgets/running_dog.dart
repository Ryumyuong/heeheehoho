import 'package:flutter/material.dart';

import '../../../home/domain/room_item.dart';
import 'dog_sprite.dart';

/// 산책 화면에서 달리는 강아지 + 착용 아이템(웨어러블).
///
/// 달리기는 전용 2프레임 스프라이트라, 홈의 [DogWithWearables]처럼 부위를 합성하지
/// 않고 스프라이트 위에 아이템 PNG를 얹는다. 앵커는 달리는 포즈(머리가 오른쪽 위)에
/// 맞춰 잡았고, 값이 안 맞으면 [_anchor]/[_scale]의 숫자만 조정하면 된다.
///
/// 털색([furColor])은 강아지 스프라이트에만 곱셈 합성으로 입히고, 아이템에는
/// 입히지 않는다(왕관·안경 등 고유 색 유지).
class RunningDog extends StatelessWidget {
  const RunningDog({
    super.key,
    required this.equipped,
    required this.furColor,
    this.size = 190,
    this.fps = 6,
  });

  final List<String> equipped;
  final Color furColor;
  final double size;
  final double fps;

  // 스프라이트 박스(size) 대비 각 아이템의 중심 위치(0~1)와 폭 비율.
  // 달리는 프레임 기준(머리 오른쪽 위, 오른쪽을 봄).
  static const Map<String, Offset> _anchor = {
    'crown': Offset(0.70, 0.12),
    'sky_ribbon': Offset(0.80, 0.15),
    'heart_glasses': Offset(0.75, 0.38),
    'green_scarf': Offset(0.58, 0.56),
  };
  static const Map<String, double> _scale = {
    'crown': 0.26,
    'sky_ribbon': 0.22,
    'heart_glasses': 0.30,
    'green_scarf': 0.34,
  };

  @override
  Widget build(BuildContext context) {
    final wearables = kRoomItems
        .where(
          (e) =>
              e.category == ItemCategory.wearable &&
              equipped.contains(e.id) &&
              e.asset != null,
        )
        .toList();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 강아지 스프라이트에만 털색을 입힌다.
          ColorFiltered(
            colorFilter: ColorFilter.mode(furColor, BlendMode.modulate),
            child: DogSprite(frames: DogFrames.run, size: size, fps: fps),
          ),
          // 아이템은 원래 색 그대로 위에 얹는다.
          for (final w in wearables)
            () {
              final a = _anchor[w.id] ?? const Offset(0.72, 0.3);
              final s = (_scale[w.id] ?? 0.28) * size;
              return Positioned(
                left: a.dx * size - s / 2,
                top: a.dy * size - s / 2,
                width: s,
                child: Image.asset(
                  w.asset!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              );
            }(),
        ],
      ),
    );
  }
}
