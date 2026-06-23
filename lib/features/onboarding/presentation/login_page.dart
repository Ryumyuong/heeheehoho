import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../pet/application/pet_providers.dart';
import 'widgets/park_scene.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  static const double _buttonRadius = 24.27;

  /// 버튼 그룹 좌우 추가 여백.
  static const double _buttonInset = 16;

  void _start(BuildContext context, WidgetRef ref, {required bool guest}) {
    ref.read(onboardingProvider.notifier).restart();
    ref.read(onboardingProvider.notifier).isGuest = guest;
    context.push('/has-pet');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7E8D1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 96),
              Image.asset(
                'assets/images/logo.png',
                height: 30,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(height: 24),
              Text(
                '네발 친구와 함께하는\n일상 속 희희호호',
                textAlign: TextAlign.center,
                style: AppText.pixel(size: 29, height: 1.5, weight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              const ParkScene(),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _buttonInset),
                child: Column(
                  children: [
                    SocialButton(
                      label: '구글로 시작하기',
                      background: Colors.white,
                      textColor: Colors.black,
                      radius: _buttonRadius,
                      badge: const _ImageBadge('assets/images/badge_google.png'),
                      onPressed: () => _start(context, ref, guest: false),
                    ),
                    const SizedBox(height: 12),
                    SocialButton(
                      label: '카카오로 시작하기',
                      background: const Color(0xFFFEE602),
                      textColor: Colors.black,
                      radius: _buttonRadius,
                      badge: const _ImageBadge('assets/images/badge_kakao.png'),
                      onPressed: () => _start(context, ref, guest: false),
                    ),
                    const SizedBox(height: 12),
                    SocialButton(
                      label: '네이버로 시작하기',
                      background: const Color(0xFF04C75B),
                      textColor: Colors.white,
                      radius: _buttonRadius,
                      badge: const _ImageBadge('assets/images/badge_naver.png'),
                      onPressed: () => _start(context, ref, guest: false),
                    ),
                    const SizedBox(height: 12),
                    SocialButton(
                      label: '비회원으로 시작하기',
                      background: AppColors.guest,
                      textColor: Colors.white,
                      radius: _buttonRadius,
                      badge: const SizedBox(width: 24),
                      onPressed: () => _start(context, ref, guest: true),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        '개인정보처리방침',
                        style: AppText.body(
                          size: 14,
                          color: const Color(0xB3000000), // #000 70%
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF747476),
                          decorationThickness: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// 소셜 버튼 좌측 로고 배지 (이미지).
class _ImageBadge extends StatelessWidget {
  const _ImageBadge(this.asset);
  final String asset;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}
