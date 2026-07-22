import 'package:flutter/material.dart';

/// 로그인 화면의 산책 일러스트.
/// (assets/images/walk_scene.png — 배경 투명 픽셀 아트, 원본 412x252)
/// 부모의 좌우 패딩(28px)을 벗어나 화면 전체 폭을 채운다.
///
/// [expand]가 true면 부모(Expanded)의 남는 세로 공간을 채우되, 그림은 아래에
/// 붙이고 위쪽 빈 곳은 투명이라 페이지 배경(크림)이 그대로 이어진다 → 세로로
/// 긴 화면에서도 "빈 박스"가 아니라 연속된 화면으로 보인다.
class ParkScene extends StatelessWidget {
  const ParkScene({super.key, this.expand = false});

  /// true면 부모 높이를 채우고 그림을 하단 정렬한다.
  final bool expand;

  static const double _ratio = 252 / 412; // height / width

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width * _ratio;

    final image = SizedBox(
      height: height,
      child: OverflowBox(
        minWidth: width,
        maxWidth: width,
        minHeight: height,
        maxHeight: height,
        alignment: Alignment.center,
        child: Image.asset(
          'assets/images/walk_scene.png',
          width: width,
          height: height,
          fit: BoxFit.fitWidth,
          filterQuality: FilterQuality.none, // 픽셀 아트 선명도 유지
        ),
      ),
    );

    if (!expand) return image;
    // 남는 세로 공간에서는 그림을 **하단에 붙이고 좌우는 절대 자르지 않는다**.
    // (contain 이라 폭에 맞춰 전체가 보이고, 위쪽 빈 곳은 투명이라 페이지색이
    //  그대로 이어져 빈 박스처럼 보이지 않는다)
    return SizedBox.expand(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: image,
      ),
    );
  }
}
