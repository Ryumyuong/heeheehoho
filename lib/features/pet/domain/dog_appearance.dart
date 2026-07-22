import 'package:flutter/material.dart';

import 'pet.dart';

/// 강아지를 "그리는 데"만 필요한 외형 값 묶음.
///
/// [Pet](저장된 펫)과 [PetDraft](온보딩 중인 초안) 양쪽에서 만들 수 있어,
/// 렌더링 위젯들은 어느 쪽에서 왔는지 신경 쓰지 않고 이것만 보면 된다.
@immutable
class DogAppearance {
  const DogAppearance({
    this.bodyShape = BodyShape.round,
    this.furColor = defaultFur,
    this.eyeStyle = EyeStyle.round,
    this.noseStyle = NoseStyle.triangle,
    this.mouthStyle = MouthStyle.smile,
  });

  factory DogAppearance.fromPet(Pet pet) => DogAppearance(
        bodyShape: pet.bodyShape,
        furColor: pet.furColor,
        eyeStyle: pet.eyeStyle,
        noseStyle: pet.noseStyle,
        mouthStyle: pet.mouthStyle,
      );

  factory DogAppearance.fromDraft(PetDraft d) => DogAppearance(
        bodyShape: d.bodyShape,
        furColor:
            d.furColorValue == null ? defaultFur : Color(d.furColorValue!),
        eyeStyle: d.eyeStyle,
        noseStyle: d.noseStyle,
        mouthStyle: d.mouthStyle,
      );

  /// 아무것도 안 고른 상태의 기본 털색(= 팔레트 첫 색).
  static const Color defaultFur = Color(0xFFC9A27E);

  final BodyShape bodyShape;
  final Color furColor;
  final EyeStyle eyeStyle;
  final NoseStyle noseStyle;
  final MouthStyle mouthStyle;

  @override
  bool operator ==(Object other) =>
      other is DogAppearance &&
      other.bodyShape == bodyShape &&
      other.furColor == furColor &&
      other.eyeStyle == eyeStyle &&
      other.noseStyle == noseStyle &&
      other.mouthStyle == mouthStyle;

  @override
  int get hashCode =>
      Object.hash(bodyShape, furColor, eyeStyle, noseStyle, mouthStyle);
}
