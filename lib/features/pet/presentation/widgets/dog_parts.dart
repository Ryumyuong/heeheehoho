import 'package:flutter/material.dart';

import '../../domain/pet.dart';
import 'dog_sprite.dart';

/// 강아지 자세. 프레임 세트를 고르는 기준.
enum DogPose { idle, walk }

/// 얼굴 파츠 한 벌의 배치.
///
/// 값은 모두 **몸통 캔버스(정사각) 대비 비율**이라 표시 크기와 무관하다.
/// 프레임마다 머리가 위아래로 움직이므로 배치도 프레임별로 따로 잡는다.
class FaceLayout {
  const FaceLayout({
    required this.eyeL,
    required this.eyeR,
    required this.snout,
    required this.cheekL,
    required this.cheekR,
  });

  final Offset eyeL;
  final Offset eyeR;
  final Offset snout;
  final Offset cheekL;
  final Offset cheekR;
}

/// 부위별 그림(레이어)이 어디 있는지 아는 카탈로그.
///
/// 강아지 = 얼굴 없는 몸통 + 얼굴 파츠 + (바깥에서) 웨어러블.
/// 얼굴 파츠는 온보딩 미리보기([PartsDog])·얼굴 맞추기 게임과 **같은 그림**을 써서,
/// 온보딩에서 만든 얼굴이 홈·미니룸에도 그대로 나온다.
///
/// ## 몸통 에셋
/// `assets/dog/body/*.png` — 기존 통짜 스프라이트에서 눈·코·입·볼 픽셀을 지우고
/// 주변 털색으로 메운 것. 전부 532x532 정사각이라 아래 비율값이 그대로 맞는다.
class DogParts {
  DogParts._();

  /// 부위별 PNG가 준비됐는지. false면 얼굴이 그려진 통짜 스프라이트로 폴백한다.
  static const bool layered = true;

  /// 몸통 레이어에 털색을 곱해(modulate) 입힐지 여부.
  ///
  /// 곱셈이라 원본보다 밝아지지는 않는다. 얼굴 파츠에는 입히지 않는다 —
  /// 검은 눈·코와 분홍 볼까지 물들면 색이 탁해진다.
  static const bool tintFur = true;

  static const List<String> _idleBody = ['assets/dog/body/idle_1.png'];
  static const List<String> _walkBody = [
    'assets/dog/body/walk_1.png',
    'assets/dog/body/walk_2.png',
  ];

  /// 몸통 프레임 경로들.
  ///
  /// [shape]는 아직 그림이 한 벌뿐이라 쓰지 않는다. 몸 모양별 아트가 들어오면
  /// 여기서 갈라주면 되고, 화면 코드는 손댈 필요 없다.
  static List<String> bodyFrames(BodyShape shape, DogPose pose) {
    if (!layered) {
      return pose == DogPose.walk ? DogFrames.walk : DogFrames.idle;
    }
    return pose == DogPose.walk ? _walkBody : _idleBody;
  }

  /// 프레임별 얼굴 배치. 원본 스프라이트에서 지운 눈·코입·볼 픽셀 덩어리의
  /// 무게중심을 그대로 쓴 값이라, 얹으면 원래 얼굴 자리에 정확히 들어간다.
  static const Map<DogPose, List<FaceLayout>> _layouts = {
    DogPose.idle: [
      FaceLayout(
        eyeL: Offset(0.5248, 0.3788),
        eyeR: Offset(0.6985, 0.3790),
        snout: Offset(0.6110, 0.4741),
        cheekL: Offset(0.4765, 0.4531),
        cheekR: Offset(0.7384, 0.4495),
      ),
    ],
    DogPose.walk: [
      FaceLayout(
        eyeL: Offset(0.5218, 0.3402),
        eyeR: Offset(0.6940, 0.3400),
        snout: Offset(0.6090, 0.4389),
        cheekL: Offset(0.4765, 0.4178),
        cheekR: Offset(0.7391, 0.4177),
      ),
      FaceLayout(
        eyeL: Offset(0.5225, 0.3509),
        eyeR: Offset(0.6940, 0.3511),
        snout: Offset(0.6105, 0.4511),
        cheekL: Offset(0.4776, 0.4289),
        cheekR: Offset(0.7396, 0.4291),
      ),
    ],
  };

  /// [pose]의 [frame]번째 얼굴 배치. 레이어 모드가 아니면 null.
  static FaceLayout? layoutFor(DogPose pose, int frame) {
    if (!layered) return null;
    final list = _layouts[pose];
    if (list == null || list.isEmpty) return null;
    return list[frame % list.length];
  }

  static const String _faceDir = 'assets/dog/face';

  static const String eyeLAsset = '$_faceDir/eye_l.png';
  static const String eyeRAsset = '$_faceDir/eye_r.png';
  static const String cheekLAsset = '$_faceDir/cheek_l.png';
  static const String cheekRAsset = '$_faceDir/cheek_r.png';

  /// 코와 입이 한 장에 같이 그려져 있어 지금은 한 종류뿐이다.
  /// `snout_tongue.png` 같은 변형 아트가 들어오면 여기에 경로만 넣으면
  /// [MouthStyle]·[NoseStyle] 선택이 바로 그림에 반영된다.
  static const Map<MouthStyle, String> _snoutVariants = {};

  static String snoutAsset(MouthStyle mouth) =>
      _snoutVariants[mouth] ?? '$_faceDir/snout.png';

  /// 눈 파츠. 변형 아트가 들어오면 마찬가지로 여기에 넣는다.
  /// 없는 동안 [EyeStyle.sleepy]는 눈을 눌러서, [EyeStyle.sparkle]은 반짝임을
  /// 덧붙여 표현한다([LayeredDog] 참고) — 온보딩 미리보기와 같은 방식이다.
  static const Map<EyeStyle, String> eyeVariants = {};

  /// 파츠 표시 크기(캔버스 대비 비율). 원본 얼굴 픽셀의 실측 크기에 맞췄고,
  /// 세로는 잘라낸 파츠 PNG의 원본 비율을 그대로 따른다.
  static const Size eyeSize = Size(29 / 532, 29 / 532 * 42 / 39);
  static const Size snoutSize = Size(72 / 532, 72 / 532 * 79 / 81);
  static const Size cheekSize = Size(38 / 532, 38 / 532);
}
