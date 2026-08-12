import 'package:flutter/material.dart';

import '../../domain/pet.dart';

/// 얼굴 파츠를 얹어 조립한 정면·앉은 자세 강아지.
///
/// 몸통은 얼굴이 비어 있는 `games/face/dog_blank.png`, 얼굴은 얼굴 맞추기 게임과
/// 같은 파츠(`games/parts/*.png`)를 쓴다. 그래서 온보딩에서 만든 강아지가 게임·홈에
/// 나오는 강아지와 같은 그림이다.
///
/// 털색은 몸통에만 곱셈 합성(modulate)으로 입힌다. 눈·코는 검정, 볼은 분홍이라
/// 파츠까지 물들이면 색이 탁해진다.
class PartsDog extends StatelessWidget {
  const PartsDog({
    super.key,
    required this.furColor,
    this.eyeStyle = EyeStyle.round,
    this.noseStyle = NoseStyle.triangle,
    this.mouthStyle = MouthStyle.smile,
    this.height = 150,
  });

  final Color furColor;
  final EyeStyle eyeStyle;
  final NoseStyle noseStyle;
  final MouthStyle mouthStyle;
  final double height;

  static const _body = 'assets/images/games/face/dog_blank.png';
  static const _partDir = 'assets/images/games/parts';

  /// dog_blank.png 원본 비율(176x245).
  static const _aspect = 176 / 245;

  /// 파츠 위치(몸통 박스 대비 중심 좌표)와 크기(몸통 가로 대비).
  ///
  /// 눈대중이 아니라 완성본 `dog_full.png`에서 실측한 값이다(얼굴이 그려진
  /// dog_full 과 빈 얼굴 dog_blank 의 차이 = 파츠 픽셀, 그 덩어리들의 중심·폭).
  /// 그래서 이대로 얹으면 완성본과 거의 같은 얼굴이 된다.
  ///
  /// 가로는 [_faceCx]를 기준으로 좌우 대칭이다.
  /// 세로는 실측값에서 눈으로 보며 다듬은 값을 유지한다(볼·코입은 조금 아래).
  ///
  /// 얼굴 맞추기 게임(`face_game_page.dart`의 `_slots`)과 같은 값이어야 하니,
  /// 한쪽을 고치면 다른 쪽도 같이 맞출 것.
  ///
  /// 얼굴 중심. **캔버스 한가운데(0.5)가 아니다** — dog_blank.png의 머리가
  /// 살짝 오른쪽에 그려져 있어서(실루엣 무게중심 0.5025~0.5035), 0.5에 맞추면
  /// 파츠가 얼굴보다 왼쪽으로 밀려 보인다. 원화(dog_full.png)의 눈 중점
  /// 0.5057·볼 중점 0.5068에 맞춘 값이다.
  static const _faceCx = 0.506;
  static const _eyeDx = 0.1307; // 눈 실측 간격의 절반
  static const _cheekDx = 0.201; // 볼 간격의 절반

  static const _eyeL = Offset(_faceCx - _eyeDx, 0.302);
  static const _eyeR = Offset(_faceCx + _eyeDx, 0.302);
  static const _cheekL = Offset(_faceCx - _cheekDx, 0.415);
  static const _cheekR = Offset(_faceCx + _cheekDx, 0.415);
  static const _snout = Offset(_faceCx, 0.4077);
  static const _eyeSize = 0.074;
  static const _cheekSize = 0.102;
  // snout.png의 투명 여백을 잘라내(87x84 → 81x79) 앵커가 곧 그림 중심이 된다.
  // 여백이 빠진 만큼 그림이 커 보이므로 표시 크기를 0.165 → 0.165×81/87로 줄였다.
  static const _snoutSize = 0.15362;

  /// 입 모양별 코·입 파츠. 코와 입이 `snout.png` 한 장에 같이 그려져 있어
  /// 지금은 한 종류뿐이다. `snout_tongue.png` 같은 변형 아트가 들어오면
  /// 여기에 경로만 넣으면 [mouthStyle] 선택이 바로 그림에 반영된다.
  static const Map<MouthStyle, String> _snoutVariants = {};

  /// 눈 파츠. 변형 아트가 들어오면 마찬가지로 여기에 넣는다.
  /// 없는 동안 [EyeStyle.sleepy]는 눈을 눌러서, [EyeStyle.sparkle]은 반짝임을
  /// 덧붙여 표현한다(아래 [_eye] 참고).
  static const Map<EyeStyle, String> _eyeVariants = {};

  String get _snoutAsset => _snoutVariants[mouthStyle] ?? '$_partDir/snout.png';

  @override
  Widget build(BuildContext context) {
    final w = height * _aspect;

    return SizedBox(
      width: w,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 몸통(얼굴 없음)에만 털색.
          ColorFiltered(
            colorFilter: ColorFilter.mode(furColor, BlendMode.modulate),
            child: Image.asset(
              _body,
              width: w,
              height: height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
          _part('$_partDir/cheek_l.png', _cheekL, _cheekSize, w),
          _part('$_partDir/cheek_r.png', _cheekR, _cheekSize, w),
          _part(_snoutAsset, _snout, _snoutSize, w),
          _eye('$_partDir/eye_l.png', _eyeL, w),
          _eye('$_partDir/eye_r.png', _eyeR, w),
        ],
      ),
    );
  }

  /// 중심 좌표(비율)에 파츠를 올린다. [sizeFrac]은 몸통 가로 대비 폭.
  Widget _part(String asset, Offset center, double sizeFrac, double w) {
    final s = sizeFrac * w;
    return Positioned(
      left: center.dx * w - s / 2,
      top: center.dy * height - s / 2,
      width: s,
      child: Image.asset(asset, fit: BoxFit.contain, filterQuality: FilterQuality.none),
    );
  }

  /// 눈 파츠 + 눈 모양 표현.
  /// - [EyeStyle.round]: 파츠 그대로
  /// - [EyeStyle.sleepy]: 세로로 눌러 감은 눈처럼
  /// - [EyeStyle.sparkle]: 파츠 위에 작은 반짝임
  Widget _eye(String base, Offset center, double w) {
    final asset = _eyeVariants[eyeStyle] ?? base;
    final s = _eyeSize * w;
    final left = center.dx * w - s / 2;
    final top = center.dy * height - s / 2;

    Widget img = Image.asset(
      asset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    );

    if (_eyeVariants[eyeStyle] == null && eyeStyle == EyeStyle.sleepy) {
      // 아래쪽을 기준으로 눌러야 눈꺼풀이 내려온 것처럼 보인다.
      img = Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()..scaleByDouble(1.0, 0.4, 1.0, 1.0),
        child: img,
      );
    }

    final eye = Positioned(left: left, top: top, width: s, child: img);
    if (_eyeVariants[eyeStyle] != null || eyeStyle != EyeStyle.sparkle) {
      return eye;
    }

    // 반짝임은 눈 바깥 위쪽에 살짝 걸치게.
    final sp = s * 0.72;
    final outward = center.dx < 0.5 ? -1 : 1;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        eye,
        Positioned(
          left: left + outward * s * 0.55,
          top: top - s * 0.45,
          width: sp,
          child: Image.asset(
            'assets/icons/sparkle_sm.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
        ),
      ],
    );
  }
}
