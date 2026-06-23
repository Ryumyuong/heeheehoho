import 'package:flutter/material.dart';

/// 로그인 화면 상단의 산책 일러스트.
/// (assets/images/walk_scene.png — 배경 투명 픽셀 아트, 원본 412x252)
/// 부모의 좌우 패딩(28px)을 벗어나 화면 전체 폭을 채운다.
class ParkScene extends StatelessWidget {
  const ParkScene({super.key});

  static const double _ratio = 252 / 412; // height / width

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width * _ratio;
    return SizedBox(
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
  }
}
