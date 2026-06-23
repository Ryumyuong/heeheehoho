import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import 'widgets/back_step_bar.dart';
import 'widgets/dog_avatar.dart';

class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const BackStepBar(),
              const Spacer(flex: 2),
              Text('스캔완료!', style: AppText.pixel(size: 24)),
              const SizedBox(height: 10),
              Text(
                '내 네발 친구와 닮았나요?',
                style: AppText.body(size: 14, color: const Color(0xFF888888)),
              ),
              const SizedBox(height: 28),
              const DraftDogAvatar(size: 150),
              const Spacer(flex: 2),
              OutlinedPillButton(
                label: '조금 더 다듬기',
                borderColor: AppColors.primary,
                textColor: AppColors.primary,
                onPressed: () => context.push('/customize'),
              ),
              const SizedBox(height: 14),
              OutlinedPillButton(
                label: '이대로 좋아요!',
                onPressed: () => context.push('/info'),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
