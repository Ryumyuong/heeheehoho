import 'package:flutter/material.dart';

import '../../domain/dog_appearance.dart';
import '../../domain/pet.dart';
import 'dog_parts.dart';
import 'dog_sprite.dart';

/// 외형([DogAppearance])에 따라 강아지 한 마리를 레이어로 합성해 그린다.
///
/// 레이어 순서: 몸통(+털색) → 볼 → 코입 → 눈.
/// 웨어러블(왕관·안경 등)은 이 위젯 바깥의 [DogWithWearables]가 그 위에 얹는다.
///
/// 얼굴 파츠는 온보딩 미리보기(`PartsDog`)와 같은 그림·같은 규칙을 쓴다.
/// 한쪽 표현을 바꾸면 다른 쪽도 같이 맞출 것.
///
/// [DogParts.layered]가 false면 얼굴이 이미 그려진 통짜 스프라이트로
/// 폴백하므로, 부위 PNG가 없어도 예전과 똑같이 보인다.
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

    final dog = DogSprite(
      frames: DogParts.bodyFrames(appearance.bodyShape, pose),
      size: size,
      fps: fps,
      breatheWhenSingle: breathe,
      // 곱셈 합성이라 밝은 털만 색이 입혀진다. 얼굴 파츠는 물들이지 않는다.
      tint: DogParts.tintFur ? appearance.furColor : null,
      overlayBuilder: _face,
    );

    if (!flip) return dog;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
      child: dog,
    );
  }

  /// [frame]번째 몸통 위에 얹을 얼굴 파츠들. 아래에서 위 순서로 쌓는다.
  List<Widget> _face(int frame) {
    final l = DogParts.layoutFor(pose, frame);
    if (l == null) return const [];
    return [
      _part(DogParts.cheekLAsset, l.cheekL, DogParts.cheekSize),
      _part(DogParts.cheekRAsset, l.cheekR, DogParts.cheekSize),
      _part(DogParts.snoutAsset(appearance.mouthStyle), l.snout,
          DogParts.snoutSize),
      ..._eye(DogParts.eyeLAsset, l.eyeL, outward: -1),
      ..._eye(DogParts.eyeRAsset, l.eyeR, outward: 1),
    ];
  }

  /// 중심 좌표(비율)에 파츠 한 장을 올린다.
  Widget _part(String asset, Offset center, Size frac, {Widget? child}) {
    final w = frac.width * size;
    final h = frac.height * size;
    return Positioned(
      left: center.dx * size - w / 2,
      top: center.dy * size - h / 2,
      width: w,
      height: h,
      child: child ??
          Image.asset(asset, fit: BoxFit.fill,
              filterQuality: FilterQuality.none),
    );
  }

  /// 눈 파츠 + 눈 모양 표현.
  /// - [EyeStyle.round]: 파츠 그대로
  /// - [EyeStyle.sleepy]: 세로로 눌러 감은 눈처럼
  /// - [EyeStyle.sparkle]: 파츠 위(바깥쪽)에 작은 반짝임
  List<Widget> _eye(String base, Offset center, {required int outward}) {
    final style = appearance.eyeStyle;
    final asset = DogParts.eyeVariants[style] ?? base;
    final custom = DogParts.eyeVariants[style] != null;

    Widget img = Image.asset(asset,
        fit: BoxFit.fill, filterQuality: FilterQuality.none);

    if (!custom && style == EyeStyle.sleepy) {
      // 아래쪽을 기준으로 눌러야 눈꺼풀이 내려온 것처럼 보인다.
      img = Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()..scaleByDouble(1.0, 0.4, 1.0, 1.0),
        child: img,
      );
    }

    final eye = _part(asset, center, DogParts.eyeSize, child: img);
    if (custom || style != EyeStyle.sparkle) return [eye];

    final w = DogParts.eyeSize.width * size;
    final h = DogParts.eyeSize.height * size;
    final sp = w * 0.72;
    return [
      eye,
      Positioned(
        left: center.dx * size - w / 2 + outward * w * 0.55,
        top: center.dy * size - h / 2 - h * 0.45,
        width: sp,
        child: Image.asset('assets/icons/sparkle_sm.png',
            fit: BoxFit.contain, filterQuality: FilterQuality.none),
      ),
    ];
  }
}
