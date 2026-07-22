import 'package:flutter/material.dart';
import '../../core/theme/pixel_theme.dart';

/// 큰 채워진 알약 버튼 (예: "다음으로", "사진 촬영하기").
class FilledPillButton extends StatelessWidget {
  const FilledPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.textColor = Colors.white,
    this.icon,
    this.iconAsset,
    this.height = 56,
    this.radius = 27,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final IconData? icon;

  /// 이미지 아이콘(에셋 경로). 지정 시 [icon]보다 우선한다.
  final String? iconAsset;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: onPressed == null ? AppColors.line : color,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconAsset != null) ...[
                Image.asset(iconAsset!, width: 20, height: 20),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 16,
                  color: textColor,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 외곽선 알약 버튼 (흰 배경, 옅은 테두리) — 예: "갤러리에서 선택", "이대로 좋아요!".
class OutlinedPillButton extends StatelessWidget {
  const OutlinedPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAsset,
    this.borderColor = AppColors.line,
    this.textColor = AppColors.ink,
    this.height = 56,
    this.fontWeight = FontWeight.w600,
    this.radius = 27,
    this.borderWidth = 1.5,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// 이미지 아이콘(에셋 경로). 지정 시 [icon]보다 우선한다.
  final String? iconAsset;
  final Color borderColor;
  final Color textColor;
  final double height;
  final FontWeight fontWeight;
  final double radius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconAsset != null) ...[
                  Image.asset(iconAsset!, width: 20, height: 20),
                  const SizedBox(width: 8),
                ] else if (icon != null) ...[
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                // 좁은 화면(접은 폰 등)에서 긴 글자가 버튼을 넘지 않게 한 줄로 축소.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AppText.body(
                        size: 16,
                        color: textColor,
                        weight: fontWeight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 선택형 칩 (커스터마이즈 옵션, 예/아니오 선택). 선택 시 오렌지 테두리+텍스트.
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: padding,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF4845F).withValues(alpha: 0.05) // #F4845F 5%
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFFFC9340) : const Color(0xFFE9E9E9),
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 14,
            color: selected ? const Color(0xFFFC9340) : AppColors.ink,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 소셜 로그인 버튼 (전체폭, 좌측 아이콘 배지 + 중앙 라벨).
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.background,
    required this.textColor,
    required this.badge,
    this.radius = 27,
  });

  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color textColor;
  final double radius;

  /// 좌측 동그란 배지 (G / 카카오 / N 등).
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Align(alignment: Alignment.centerLeft, child: badge),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 13.63,
                  color: textColor,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
