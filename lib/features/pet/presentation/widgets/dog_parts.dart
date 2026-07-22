import 'package:flutter/material.dart';

import '../../domain/dog_appearance.dart';
import '../../domain/pet.dart';
import 'dog_sprite.dart';

/// 강아지 자세. 프레임 세트를 고르는 기준.
enum DogPose { idle, walk }

/// 겹쳐 그리는 얼굴 부위. 나열 순서가 곧 그리는 순서(아래 → 위).
enum FacePart { mouth, nose, eyes }

/// 부위별 그림(레이어)이 어디 있는지 아는 카탈로그.
///
/// 강아지를 "몸통 + 얼굴 부위 + (기존) 웨어러블"의 레이어로 합성하기 위한 기초.
/// 지금은 각 레이어가 PNG지만, 나중에 픽셀(코드)로 그리도록 업그레이드할 때
/// 화면 코드는 그대로 두고 이 파일과 [LayeredDog]의 레이어 생성 부분만 바꾸면 된다.
///
/// ## 부위 PNG를 넣을 때
/// 1. 아래 [layered]를 true로 바꾼다.
/// 2. 이 경로 규칙대로 파일을 넣는다(pubspec에 `assets/dog/` 폴더 등록 필요).
///    - 몸통: `assets/dog/body/{몸모양}_{자세}_{프레임번호}.png` (얼굴 없는 몸통만)
///      예) `round_idle_1.png`, `round_walk_1.png`, `round_walk_2.png`
///    - 얼굴: `assets/dog/face/{부위}_{스타일}.png`
///      예) `eyes_round.png`, `nose_heart.png`, `mouth_tongue.png`
/// 3. [faceAnchor] / [faceSize] 값을 실제 그림에 맞게 미세 조정한다.
class DogParts {
  DogParts._();

  /// 부위별 PNG가 준비됐는지. false인 동안은 얼굴이 이미 그려진 통짜
  /// 스프라이트([DogFrames])로 폴백하고, 얼굴 레이어는 그리지 않는다.
  static const bool layered = false;

  /// 몸통 레이어에 털색을 곱해(modulate) 입힐지 여부.
  ///
  /// 통짜 스프라이트에도 쓸 수 있다. 곱셈이라 검은 눈·코는 검은색으로 남고
  /// 크림색 털만 물들기 때문. 다만 원본보다 밝아질 수는 없다.
  static const bool tintFur = true;

  /// 자세별 프레임 장수(레이어 모드에서 기대하는 파일 수).
  static const Map<DogPose, int> _frameCount = {
    DogPose.idle: 1,
    DogPose.walk: 2,
  };

  /// 몸통 프레임 경로들. 레이어 준비 전에는 기존 통짜 스프라이트를 그대로 쓴다.
  static List<String> bodyFrames(BodyShape shape, DogPose pose) {
    if (!layered) {
      return pose == DogPose.walk ? DogFrames.walk : DogFrames.idle;
    }
    final n = _frameCount[pose] ?? 1;
    return [
      for (var i = 1; i <= n; i++)
        'assets/dog/body/${shape.name}_${pose.name}_$i.png',
    ];
  }

  /// 얼굴 부위 경로. 레이어 준비 전(= 통짜 스프라이트에 얼굴이 포함)에는 null.
  static String? faceAsset(FacePart part, DogAppearance a) {
    if (!layered) return null;
    final style = switch (part) {
      FacePart.eyes => a.eyeStyle.name,
      FacePart.nose => a.noseStyle.name,
      FacePart.mouth => a.mouthStyle.name,
    };
    return 'assets/dog/face/${part.name}_$style.png';
  }

  /// 얼굴 부위의 중심 위치. 강아지 박스 크기에 대한 비율(0~1)이라 크기와 무관.
  /// 현재 그림 기준 머리가 오른쪽에 치우쳐 있어 x가 0.5보다 크다.
  /// (실제 부위 PNG가 들어오면 눈으로 보며 조정할 값)
  static const Map<FacePart, Offset> faceAnchor = {
    FacePart.eyes: Offset(0.63, 0.36),
    FacePart.nose: Offset(0.63, 0.44),
    FacePart.mouth: Offset(0.63, 0.50),
  };

  /// 얼굴 부위의 표시 크기. 역시 박스 대비 비율(가로, 세로).
  static const Map<FacePart, Size> faceSize = {
    FacePart.eyes: Size(0.34, 0.10),
    FacePart.nose: Size(0.10, 0.08),
    FacePart.mouth: Size(0.18, 0.12),
  };
}
