import 'package:flutter/material.dart';

import '../../core/theme/pixel_theme.dart';

/// 헤더의 보유 화폐 칩(흰 알약 + 아이콘 + 숫자).
///
/// 발자국(미니룸 아이템)과 뼈다귀(마켓 실물)를 같은 모양으로 보여준다.
/// 홈·스토어가 이 위젯을 공유해 두 화면의 헤더가 어긋나지 않는다.
class WalletChip extends StatelessWidget {
  const WalletChip.paws(this.amount, {super.key, this.onTap})
    : icon = 'assets/icons/paw.png',
      background = const Color(0xFFFFF3E0);

  const WalletChip.bones(this.amount, {super.key, this.onTap})
    : icon = 'assets/icons/bone.png',
      background = const Color(0xFFFFF8F0);

  final String icon;

  /// 화폐별 칩 배경(발자국은 조금 더 진한 크림, 뼈다귀는 옅은 크림).
  final Color background;

  /// 이미 천단위 콤마가 찍힌 문자열.
  final String amount;

  /// 탭하면 실행(예: 발자국 칩 → 충전 페이지). null이면 탭 안 됨.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = _chip();
    if (onTap == null) return chip;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
    );
  }

  Widget _chip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(500),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            width: 18,
            height: 18,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(width: 6),
          Text(
            amount,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w700,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }
}
