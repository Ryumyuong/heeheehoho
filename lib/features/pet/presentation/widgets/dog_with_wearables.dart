import 'package:flutter/material.dart';

import '../../../home/domain/room_item.dart';
import '../../domain/dog_appearance.dart';
import 'dog_parts.dart';
import 'layered_dog.dart';

/// 강아지 + 장착 웨어러블을 하나로 묶은 위젯.
///
/// 강아지와 웨어러블을 같은 숨쉬기(상하) 모션으로 함께 움직여, 장착템이
/// 강아지와 따로 놀지 않게 한다. 내부 설계 좌표는 150 박스 / 130 강아지 기준이며,
/// 바깥에서 [FittedBox] 등으로 원하는 크기로 스케일해서 쓴다.
///
/// 홈과 스토어(미니룸 프리뷰)가 이 위젯을 공유해 착용 위치/크기가 항상 일치한다.
class DogWithWearables extends StatefulWidget {
  const DogWithWearables({
    super.key,
    required this.equipped,
    this.appearance = const DogAppearance(),
    this.walking = false,
    this.flip = false,
    this.breathe = true,
  });

  /// 장착된 아이템 id 목록(웨어러블만 그려짐).
  final List<String> equipped;

  /// 몸 모양·털색·눈·코·입. 온보딩에서 고른 값이 그대로 여기로 들어온다.
  final DogAppearance appearance;

  final bool walking;
  final bool flip;

  /// 숨쉬기(상하) 모션 on/off.
  final bool breathe;

  /// 내부 설계 기준 박스 크기(정사각). 강아지 스프라이트는 이 안에서 130.
  static const double designBox = 150;

  @override
  State<DogWithWearables> createState() => _DogWithWearablesState();
}

class _DogWithWearablesState extends State<DogWithWearables>
    with SingleTickerProviderStateMixin {
  // DogSprite 내부 모션과 동일 주기(1600ms)로, 강아지와 웨어러블을 함께 상하 이동.
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wearables = kRoomItems
        .where((e) =>
            e.category == ItemCategory.wearable &&
            widget.equipped.contains(e.id))
        .toList();

    final content = SizedBox(
      width: DogWithWearables.designBox,
      height: DogWithWearables.designBox,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          LayeredDog(
            appearance: widget.appearance,
            pose: widget.walking ? DogPose.walk : DogPose.idle,
            flip: widget.flip,
            size: 130,
            // 상하 모션은 여기서 강아지+웨어러블을 함께 처리하므로 끈다.
            breathe: false,
          ),
          // 웨어러블 픽셀 에셋을 강아지 머리/눈/목 위치에 배치.
          // 강아지 머리가 이미지 우측에 있어 오프셋이 오른쪽으로 치우친다.
          for (final w in wearables)
            if (w.asset != null)
              () {
                // 걷기(새 비숑 프레임)는 머리가 가운데라 앵커가 다르다.
                final anchor = (widget.walking
                        ? (_wearAnchorWalk[w.id] ?? _wearAnchor[w.id])
                        : _wearAnchor[w.id]) ??
                    Offset.zero;
                final sz = _wearSize[w.id] ?? const Size(44, 44);
                // 산책 중 좌우 반전 시 가로 위치도 함께 반전.
                final dx = widget.flip ? -anchor.dx : anchor.dx;
                return Positioned(
                  left: 75 + dx - sz.width / 2,
                  top: 75 + anchor.dy - sz.height / 2,
                  child: Image.asset(
                    w.asset!,
                    width: sz.width,
                    height: sz.height,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
                );
              }(),
        ],
      ),
    );

    if (!widget.breathe) return content;

    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, child) {
        // DogSprite와 동일한 삼각파: 세로 살짝 신축 + 미세 상하.
        final s = (1 - (2 * _breathe.value - 1).abs());
        final dy = -2.0 * s;
        final scaleY = 1.0 + 0.035 * s;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()..scaleByDouble(1.0, scaleY, 1.0, 1.0),
            child: child,
          ),
        );
      },
      child: content,
    );
  }

  // 강아지 중심(75,75) 기준 웨어러블 오프셋.
  // 안경=눈 / 왕관=머리 위 중앙 / 리본=머리 약간 오른쪽 / 스카프=목~가슴.
  //
  // dog.webp를 걷기 프레임과 같은 532 캔버스로 다시 채우면서 idle 강아지가
  // 박스 안에서 조금 작아지고 아래로 내려갔다. 그만큼 앵커도 같이 옮겼다.
  static const Map<String, Offset> _wearAnchor = {
    'crown': Offset(15, -47), // 머리 위 중앙
    'straw_hat': Offset(15, -44), // 챙이 넓어 왕관보다 살짝 아래
    'heart_glasses': Offset(15, -15), // 눈 위치
    'round_glasses': Offset(15, -15), // 하트안경과 같은 눈 위치
    'sky_ribbon': Offset(25, -41), // 머리 위, 왕관보다 약간 오른쪽
    'pink_ribbon': Offset(25, -41), // 하늘색 리본과 같은 자리
    // 턱 바로 아래 목. 가슴까지 내리면 스카프가 아니라 앞치마처럼 보인다.
    'green_scarf': Offset(17, 17),
  };

  // 걷기(새 비숑) 프레임용 앵커. 비숑은 머리가 가운데라 dx를 0 근처로 모은다.
  // 값이 안 맞으면 이 숫자만 조정하면 된다.
  static const Map<String, Offset> _wearAnchorWalk = {
    'crown': Offset(13, -50),
    'straw_hat': Offset(13, -47),
    'heart_glasses': Offset(14, -22), // 눈에 딱 맞게
    'round_glasses': Offset(14, -22),
    'sky_ribbon': Offset(25, -44),
    'pink_ribbon': Offset(25, -44),
    'green_scarf': Offset(10, 14),
  };

  // 원본 비율 유지한 표시 크기(그림의 알파 영역 가로:세로 비를 따른다).
  static const Map<String, Size> _wearSize = {
    'crown': Size(50, 46),
    'straw_hat': Size(56, 35), // 136x85
    'heart_glasses': Size(54, 27),
    'round_glasses': Size(54, 21), // 117x45
    'sky_ribbon': Size(42, 27),
    'pink_ribbon': Size(44, 30), // 99x67
    // 새 반다나 픽셀 비율에 맞춘 크기(113x70).
    'green_scarf': Size(52, 32),
  };
}
