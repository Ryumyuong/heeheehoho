import 'package:flutter/material.dart';

import '../../domain/dog_appearance.dart';
import 'dog_parts.dart';
import 'dog_sprite.dart';

/// 외형([DogAppearance])에 따라 강아지 한 마리를 레이어로 합성해 그린다.
///
/// 레이어 순서: 몸통(+털색) → 입 → 코 → 눈.
/// 웨어러블(왕관·안경 등)은 이 위젯 바깥의 [DogWithWearables]가 그 위에 얹는다.
///
/// [DogParts.layered]가 false인 동안은 얼굴이 이미 그려진 통짜 스프라이트로
/// 폴백하므로, 부위 PNG가 없어도 지금과 똑같이 보인다.
class LayeredDog extends StatelessWidget {
  const LayeredDog({
    super.key,
    this.appearance = const DogAppearance(),
    this.pose = DogPose.idle,
    this.size = 130,
    this.flip = false,
    this.breathe = false,
  });

  final DogAppearance appearance;
  final DogPose pose;
  final double size;

  /// 좌우 반전(왼쪽으로 걸을 때).
  final bool flip;

  /// 단일 프레임일 때만 쓰는 숨쉬기 폴백. 상위에서 몸+웨어러블을 함께
  /// 움직이는 경우(홈)에는 false로 두고 상위가 처리한다.
  final bool breathe;

  @override
  Widget build(BuildContext context) {
    // 걷기는 2프레임 교대라 프레임당 200ms(5fps)가 가장 자연스럽다.
    final fps = pose == DogPose.walk ? 5.0 : 6.0;

    Widget body = DogSprite(
      frames: DogParts.bodyFrames(appearance.bodyShape, pose),
      size: size,
      fps: fps,
      breatheWhenSingle: breathe,
    );

    if (DogParts.tintFur) {
      // 곱셈 합성이라 어두운 눈·코는 그대로 남고 밝은 털만 색이 입혀진다.
      body = ColorFiltered(
        colorFilter: ColorFilter.mode(appearance.furColor, BlendMode.modulate),
        child: body,
      );
    }

    final faces = <Widget>[
      for (final part in FacePart.values)
        if (DogParts.faceAsset(part, appearance) case final asset?)
          _positionedFace(part, asset),
    ];

    final dog = faces.isEmpty
        ? body
        : SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [Positioned.fill(child: body), ...faces],
            ),
          );

    if (!flip) return dog;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
      child: dog,
    );
  }

  Widget _positionedFace(FacePart part, String asset) {
    final anchor = DogParts.faceAnchor[part] ?? const Offset(0.5, 0.5);
    final frac = DogParts.faceSize[part] ?? const Size(0.2, 0.2);
    final w = frac.width * size;
    final h = frac.height * size;
    return Positioned(
      left: anchor.dx * size - w / 2,
      top: anchor.dy * size - h / 2,
      child: Image.asset(
        asset,
        width: w,
        height: h,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}
