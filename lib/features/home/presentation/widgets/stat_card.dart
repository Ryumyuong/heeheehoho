import 'package:flutter/material.dart';
import '../../../../core/theme/pixel_theme.dart';

/// 좌상단 스탯 카드: 행복도 / 배고픔 / 피로도.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.happiness,
    required this.hunger,
    required this.fatigue,
  });

  final int happiness;
  final int hunger;
  final int fatigue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          _StatRow(emoji: '❤️', label: '행복도', value: happiness, color: AppColors.statHappy),
          const SizedBox(height: 8),
          _StatRow(emoji: '🦴', label: '배고픔', value: hunger, color: AppColors.statHunger),
          const SizedBox(height: 8),
          _StatRow(emoji: '⚡', label: '피로도', value: fatigue, color: AppColors.statFatigue),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });
  final String emoji;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        SizedBox(
          width: 38,
          child: Text(label,
              style: AppText.body(size: 10, weight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (value / 100).clamp(0, 1)),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, t, _) => LinearProgressIndicator(
                value: t,
                minHeight: 7,
                backgroundColor: AppColors.line,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
