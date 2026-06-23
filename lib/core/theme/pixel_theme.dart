import 'package:flutter/material.dart';

/// heeheehoho 디자인 팔레트.
class AppColors {
  AppColors._();

  static const Color splashOrange = Color(0xFFEE8E43); // 스플래시 배경
  static const Color primary = Color(0xFFF2994A); // 메인 오렌지(버튼/활성탭)
  static const Color primarySoft = Color(0xFFFAD9B8); // 연한 오렌지 테두리
  static const Color coral = Color(0xFFF47B56); // 로고/강조 텍스트
  static const Color cream = Color(0xFFF4EAD6); // 기본 배경
  static const Color creamPanel = Color(0xFFFBF6EC); // 카드/원형 배경
  static const Color ink = Color(0xFF3D3D3D); // 본문 텍스트
  static const Color subtle = Color(0xFF9E9E9E); // 보조 텍스트
  static const Color line = Color(0xFFE3E3E3); // 외곽선/구분선
  static const Color brownIcon = Color(0xFF9C6B43); // 가구/나무 톤

  // 스탯 바 색
  static const Color statHappy = Color(0xFFF47B56); // 행복도
  static const Color statHunger = Color(0xFFF2994A); // 배고픔
  static const Color statFatigue = Color(0xFF8C7AE6); // 피로도

  // 소셜 로그인
  static const Color kakao = Color(0xFFFEE500);
  static const Color kakaoText = Color(0xFF3C1E1E);
  static const Color naver = Color(0xFF03C75A);
  static const Color guest = Color(0xFF2E2E2E);

  // 강아지 커스터마이즈 색상 팔레트
  static const List<Color> furColors = [
    Color(0xFFC9A27E), // 베이지브라운
    Color(0xFFF2F0EB), // 화이트
    Color(0xFF3A3A3A), // 블랙
    Color(0xFF6B4A2B), // 브라운
    Color(0xFFE8D7BE), // 크림
  ];
}

class AppText {
  AppText._();

  static const String pixelFamily = 'LanaPixel';

  /// 픽셀 헤딩 (한글 포함). LanaPixel은 11px 기준 디자인이라 정수배 스케일 권장.
  static TextStyle pixel({
    double size = 22,
    Color color = const Color(0xFF2D2D2D),
    double height = 1.5,
    FontWeight weight = FontWeight.normal,
  }) =>
      TextStyle(
        fontFamily: pixelFamily,
        fontSize: size,
        color: color,
        height: height,
        fontWeight: weight,
        letterSpacing: 0.5,
      );

  /// 본문 (Noto Sans KR, 번들 폰트).
  static TextStyle body({
    double size = 14,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
  }) =>
      TextStyle(
        fontFamily: 'NotoSansKR',
        fontSize: size,
        color: color,
        fontWeight: weight,
        // NotoSansKR은 가변 폰트(wght 100~900, 기본 100/Thin)라
        // fontWeight만으로는 웹에서 굵기가 반영되지 않아 가변 축을 명시한다.
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        height: height,
      );

  /// 로고 (Pacifico).
  static TextStyle logo({double size = 30, Color color = AppColors.coral}) =>
      TextStyle(fontFamily: 'Pacifico', fontSize: size, color: color);
}

class PixelTheme {
  PixelTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.cream,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            fontFamily: 'NotoSansKR',
            bodyColor: AppColors.ink,
            displayColor: AppColors.ink,
          ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
