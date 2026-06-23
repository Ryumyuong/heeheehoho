import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/pixel_theme.dart';

/// "← 이전단계" 상단 바.
class BackStepBar extends StatelessWidget {
  const BackStepBar({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onBack ?? () => context.pop(),
        icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.subtle),
        label: Text('이전단계', style: AppText.body(size: 14, color: AppColors.subtle)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: AppColors.subtle,
        ),
      ),
    );
  }
}

/// 3단계 진행 점 (정보입력 화면).
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count * 2 - 1, (i) {
        if (i.isOdd) {
          return Container(width: 36, height: 2, color: AppColors.line);
        }
        final idx = i ~/ 2;
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: idx <= active ? AppColors.primary : AppColors.line,
          ),
        );
      }),
    );
  }
}
