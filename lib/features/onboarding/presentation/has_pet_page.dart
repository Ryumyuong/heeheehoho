import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../pet/application/pet_providers.dart';
import 'widgets/back_step_bar.dart';

class HasPetPage extends ConsumerWidget {
  const HasPetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void choose(bool has) {
      ref.read(onboardingProvider.notifier).update((d) => d.hasExistingPet = has);
      // 있으면 사진으로, 없으면 바로 커스터마이즈.
      context.push(has ? '/photo' : '/customize');
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const BackStepBar(),
              const Spacer(flex: 3),
              Text(
                '당신의 일상에 함께하는\n네발 친구가 있나요?',
                textAlign: TextAlign.center,
                style: AppText.pixel(size: 24, height: 1.6),
              ),
              const Spacer(flex: 2),
              OutlinedPillButton(
                label: '네, 귀여운 네발 친구가 있어요',
                borderColor: AppColors.primary,
                textColor: const Color(0xFFFC9340),
                fontWeight: FontWeight.w700,
                onPressed: () => choose(true),
              ),
              const SizedBox(height: 14),
              OutlinedPillButton(
                label: '아니요, 저도 네발 친구가 있었으면 좋겠어요!',
                textColor: Colors.black,
                fontWeight: FontWeight.w500,
                onPressed: () => choose(false),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}
