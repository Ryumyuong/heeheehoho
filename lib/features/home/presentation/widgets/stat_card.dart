import 'package:flutter/material.dart';
import '../../../../core/theme/pixel_theme.dart';

/// 좌상단 스탯 카드: 애정도 / 포만감 / 피로도.
///
/// 두 번째 값은 게이지가 찰수록 배부른 상태다. 예전 라벨이 '배고픔'이라
/// 의미가 거꾸로 읽혔다(가득 차 있는데 배고픔?) — '포만감'으로 바로잡았다.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.happiness,
    required this.hunger,
    required this.fatigue,
    this.width = 215,
  });

  final int happiness;
  final int hunger;
  final int fatigue;

  /// 카드(게이지 포함) 폭. 좁은 화면에서 오른쪽 버튼과 겹치지 않게 줄여 넘긴다.
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _StatRow(icon: 'assets/icons/stat_happy.png', label: '애정도', value: happiness, color: AppColors.statHappy),
          const SizedBox(height: 8),
          _StatRow(icon: 'assets/icons/stat_hunger.png', label: '포만감', value: hunger, color: AppColors.statHunger),
          const SizedBox(height: 8),
          _StatRow(icon: 'assets/icons/stat_fatigue.png', label: '피로도', value: fatigue, color: AppColors.statFatigue),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final String icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(icon,
            width: 14, height: 14, filterQuality: FilterQuality.none),
        const SizedBox(width: 4),
        SizedBox(
          width: 38,
          child: Text(label,
              style: AppText.body(size: 10, weight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (value / 100).clamp(0, 1)),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, t, _) => LinearProgressIndicator(
                value: t,
                minHeight: 7,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: AppColors.statTrack,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
