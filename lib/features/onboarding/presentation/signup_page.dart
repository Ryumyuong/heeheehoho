import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/domain/pet.dart';
import '../../pet/presentation/widgets/pixel_dog.dart';

class SignupPage extends ConsumerWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(petProvider);
    final name = pet?.name ?? '친구';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 36),
              Text('heeheehoho', style: AppText.logo(size: 28)),
              const SizedBox(height: 18),
              Text('아직 계정이 없으신가요?', style: AppText.pixel(size: 24)),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  style: AppText.body(size: 14, color: AppColors.subtle),
                  children: [
                    const TextSpan(text: '간편 회원가입 후 '),
                    TextSpan(
                      text: name,
                      style: AppText.body(
                          size: 14,
                          color: AppColors.coral,
                          weight: FontWeight.w700),
                    ),
                    const TextSpan(text: '와의\n희희호호 일상을 시작하세요'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                    color: AppColors.creamPanel, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: PixelDogFace(
                  furColor: pet?.furColor ?? AppColors.furColors[0],
                  eyeStyle: pet?.eyeStyle ?? EyeStyle.round,
                  noseStyle: pet?.noseStyle ?? NoseStyle.triangle,
                  mouthStyle: pet?.mouthStyle ?? MouthStyle.smile,
                  size: 92,
                ),
              ),
              const Spacer(),
              SocialButton(
                label: '구글로 시작하기',
                background: Colors.white,
                textColor: AppColors.ink,
                badge: _circleText('G', const Color(0xFF4285F4)),
                onPressed: () {
                  ref.read(isGuestProvider.notifier).setGuest(false);
                  context.go('/home');
                },
              ),
              const SizedBox(height: 12),
              SocialButton(
                label: '카카오로 시작하기',
                background: AppColors.kakao,
                textColor: AppColors.kakaoText,
                badge: _circleText('K', AppColors.kakaoText),
                onPressed: () {
                  ref.read(isGuestProvider.notifier).setGuest(false);
                  context.go('/home');
                },
              ),
              const SizedBox(height: 12),
              SocialButton(
                label: '네이버로 시작하기',
                background: AppColors.naver,
                textColor: Colors.white,
                badge: _circleText('N', Colors.white, bg: Colors.transparent),
                onPressed: () {
                  ref.read(isGuestProvider.notifier).setGuest(false);
                  context.go('/home');
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text('개인정보처리방침',
                    style: AppText.body(size: 12, color: AppColors.subtle)
                        .copyWith(decoration: TextDecoration.underline)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleText(String t, Color fg, {Color bg = Colors.white}) => Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(t,
            style: TextStyle(
                color: fg, fontWeight: FontWeight.w900, fontSize: 15)),
      );
}
