import 'package:flutter/material.dart';

/// heeheehoho 디자인 팔레트.
class AppColors {
  AppColors._();

  static const Color splashOrange = Color(0xFFFC9340); // 스플래시 배경
  static const Color primary = Color(0xFFFC9340); // 메인 오렌지(버튼/활성탭)
  static const Color primarySoft = Color(0xFFFAD9B8); // 연한 오렌지 테두리
  static const Color coral = Color(0xFFF47B56); // 로고/강조 텍스트
  static const Color cream = Color(0xFFF4EAD6); // 기본 배경
  static const Color creamPanel = Color(0xFFFBF6EC); // 카드/원형 배경
  static const Color ink = Color(0xFF3D3D3D); // 본문 텍스트
  static const Color subtle = Color(0xFF9E9E9E); // 보조 텍스트
  static const Color line = Color(0xFFE3E3E3); // 외곽선/구분선
  static const Color brownIcon = Color(0xFF9C6B43); // 가구/나무 톤

  // 스탯 바 색
  static const Color statHappy = Color(0xFFF4845F); // 행복도
  static const Color statHunger = Color(0xFFFFD166); // 배고픔
  static const Color statFatigue = Color(0xFF7E6DFF); // 피로도
  static const Color statTrack = Color(0xFFD9D9D9); // 게이지 안채워진 곳

  // 소셜 로그인
  static const Color kakao = Color(0xFFFEE500);
  static const Color kakaoText = Color(0xFF3C1E1E);
  static const Color naver = Color(0xFF03C75A);
  static const Color guest = Color(0xFF2E2E2E);

  // 강아지 커스터마이즈 색상 팔레트
  /// 털색 팔레트. 스프라이트에 곱셈 합성(modulate)으로 입히므로 실제 개 털색
  /// 범위를 벗어나지 않는 색만 넣는다.
  ///
  /// 앞의 5색은 기존 순서를 그대로 유지한다 — 저장된 펫이 `furColorValue`(ARGB)로
  /// 색을 들고 있고 기본값이 `furColors[0]`이라, 순서를 바꾸면 기존 사용자의
  /// 강아지 색이 바뀐다. 새 색은 항상 뒤에 붙일 것.
  ///
  /// 사진 분석([analyzeDogPhoto])은 이 목록에서 Lab 거리가 가장 가까운 색을
  /// 고르므로, 색이 촘촘할수록 사진 추정도 정확해진다.
  static const List<Color> furColors = [
    Color(0xFFC9A27E), // 베이지브라운
    Color(0xFFF2F0EB), // 화이트
    Color(0xFF3A3A3A), // 블랙
    Color(0xFF6B4A2B), // 브라운
    Color(0xFFE8D7BE), // 크림
    Color(0xFFE5A84C), // 골드
    Color(0xFFF2B48C), // 살구
    Color(0xFFB5713F), // 시나몬
    Color(0xFF8C3F2A), // 적갈
    Color(0xFF4A2E1E), // 초코
    Color(0xFFC3BDB4), // 실버
    Color(0xFF8E8880), // 그레이
    Color(0xFF9BA3A8), // 애쉬블루
    Color(0xFF6E6963), // 차콜
    // 순백. 털색은 곱셈 합성이라 이 값만 원본 그림을 그대로 남긴다
    // (기존 '화이트' 0xFFF2F0EB 는 5%쯤 어두워져 아이보리에 가깝다).
    Color(0xFFFFFFFF), // 흰색
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

  /// 본문 (기본 Noto Sans KR). [family]로 다른 가변 폰트(예: Pretendard) 지정 가능.
  static TextStyle body({
    double size = 14,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
    String family = 'NotoSansKR',
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        color: color,
        fontWeight: weight,
        // NotoSansKR·Pretendard 모두 가변 폰트(wght 축)라
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
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: const WidgetStatePropertyAll(Color(0xFFFC9340)),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(4),
      ),
    );
  }
}
