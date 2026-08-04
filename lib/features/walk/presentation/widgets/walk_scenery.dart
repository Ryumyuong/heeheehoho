import 'package:flutter/material.dart';

/// 산책 중 배경. 같은 그림을 가로로 이어 붙여 흘려보내 "걷고 있음"을 표현한다.
///
/// 배경은 [WalkBackground]로 갈아끼운다. 지역마다 다른 그림을 쓰거나, 나중에
/// AI 생성 이미지를 쓰게 되면 [WalkBackground.image]에 `NetworkImage`를 넣으면
/// 되고 레이아웃은 그대로다.
class WalkScenery extends StatefulWidget {
  const WalkScenery({
    super.key,
    this.background = WalkBackground.city,
    this.speed = 1.0,
  });

  final WalkBackground background;

  /// 흐르는 배속. 1.0이 보통 걷기, 0이면 멈춘다.
  /// 거리가 늘어나는 속도를 그대로 받아 강아지·먼지와 같은 페이스로 움직인다.
  final double speed;

  @override
  State<WalkScenery> createState() => _WalkSceneryState();
}

/// 지역별 산책 배경 한 장. [aspect]는 그림의 가로/세로 비율.
class WalkBackground {
  const WalkBackground({required this.image, required this.aspect});

  final ImageProvider image;
  final double aspect;

  /// 도시 강변(기본). 1236x1665.
  static const city = WalkBackground(
    image: AssetImage('assets/images/walk_bg_city.webp'),
    aspect: 1236 / 1665,
  );

  /// 지역 + 시간대에 맞는 배경.
  ///
  /// 배경 16장은 지역(서울·부산·제주·인천) × 시간(새벽·아침·저녁·밤) 순으로
  /// bg_01~16에 들어 있다. 지역은 [place](역지오코딩 지역명)으로, 시간은
  /// [now]의 시각으로 고른다. 모두 1236x1665.
  factory WalkBackground.forPlaceAndTime(String place, DateTime now) {
    // 지역 → bg 시작 인덱스(0/4/8/12). 못 알아보면 서울.
    int region;
    if (place.contains('부산') || place.contains('해운대') || place.contains('광안')) {
      region = 4; // 부산
    } else if (place.contains('제주') || place.contains('성산')) {
      region = 8; // 제주
    } else if (place.contains('인천') || place.contains('송도')) {
      region = 12; // 인천
    } else {
      region = 0; // 서울(기본)
    }
    // 시각 → 시간대 오프셋(새벽0 / 아침1 / 저녁2 / 밤3).
    final h = now.hour;
    final int t = (h >= 5 && h < 7)
        ? 0
        : (h >= 7 && h < 17)
            ? 1
            : (h >= 17 && h < 20)
                ? 2
                : 3;
    final n = (region + t + 1).toString().padLeft(2, '0'); // bg_01~16
    return WalkBackground(
      image: AssetImage('assets/images/games/bg/bg_$n.webp'),
      aspect: 1236 / 1665,
    );
  }
}

class _WalkSceneryState extends State<WalkScenery>
    with SingleTickerProviderStateMixin {
  // 보통 걷기(배속 1.0)에서 그림 한 장이 지나가는 시간.
  static const _baseDuration = Duration(seconds: 14);

  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _applySpeed();
  }

  @override
  void didUpdateWidget(covariant WalkScenery old) {
    super.didUpdateWidget(old);
    if (widget.speed != old.speed) _applySpeed();
  }

  /// 배속이 바뀌면 주기를 다시 잡고, 멈춤(0)이면 그 자리에 세운다.
  void _applySpeed() {
    if (widget.speed <= 0) {
      _c.stop();
      return;
    }
    _c.duration = _baseDuration * (1 / widget.speed);
    // 진행 위상(_c.value)은 유지되므로 배속을 바꿔도 배경이 튀지 않는다.
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) {
          final h = box.maxHeight;
          // 그림은 높이에 맞춰 세우고, 그만큼의 폭으로 가로로 이어 붙인다.
          final tileW = h * widget.background.aspect;
          if (tileW <= 0) return const SizedBox.shrink();
          // 화면을 덮고 + 한 장이 더 있어야 스크롤이 끊기지 않는다(최소 3장).
          final count = ((box.maxWidth / tileW).ceil() + 1).clamp(3, 8);

          return AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.translate(
              // 0 → -tileW 로 밀고 다시 0으로 돌아오므로 이음매가 안 보인다.
              offset: Offset(-_c.value * tileW, 0),
              child: child,
            ),
            // 이어붙인 타일이 화면보다 넓다. OverflowBox로 Row에 무한 폭을 줘야
            // Row가 "오버플로" 경고를 내지 않는다(그림은 바깥 ClipRect가 자른다).
            child: OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < count; i++)
                    Image(
                      image: widget.background.image,
                      width: tileW,
                      height: h,
                      // fill: 계산한 타일 폭에 정확히 맞춰야 장끼리 틈이 안 생긴다.
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none, // 픽셀 선명도 유지
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
