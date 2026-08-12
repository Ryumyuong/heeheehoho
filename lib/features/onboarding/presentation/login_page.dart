import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../legal/presentation/privacy_policy_dialog.dart';
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
    ref.read(isGuestProvider.notifier).setGuest(guest);
    context.push('/has-pet');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7E8D1),
      body: SafeArea(
        // 로고·문구는 위, 버튼은 아래에 두고, 가운데 산책 일러스트가 남는 세로
        // 공간을 채운다(빈 크림 여백 없이). 화면이 짧으면 스크롤된다(버튼 안 잘림).
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  48, // 위 vertical 패딩(24×2)
            ),
            // IntrinsicHeight: 콘텐츠가 화면보다 짧을 때 Column을 화면 높이로
            // 늘려, Expanded(일러스트)가 남는 공간을 실제로 채우게 한다.
            child: IntrinsicHeight(
              child: Column(
                children: [
                  _logo(),
                  const SizedBox(height: 24),
                  _tagline(),
                  const SizedBox(height: 20),
                  // 남는 세로 공간을 일러스트가 채운다(그림은 하단, 위는 페이지색).
                  const Expanded(child: ParkScene(expand: true)),
                  const SizedBox(height: 20),
                  _buttons(context, ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() => Image.asset(
    'assets/images/logo.png',
    height: 30,
    filterQuality: FilterQuality.medium,
  );

  Widget _tagline() => Text(
    '네발 친구와 함께하는\n일상 속 희희호호',
    textAlign: TextAlign.center,
    style: AppText.pixel(size: 29, height: 1.5, weight: FontWeight.w600),
  );

  Widget _buttons(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _buttonInset),
    child: Column(
      children: [
        // 실제 인증이 붙기 전까지 소셜 버튼은 감춘다([kSocialLoginEnabled]).
        if (kSocialLoginEnabled) ...[
          // Sign in with Apple. 애플은 다른 소셜 로그인을 제공하면 이것도
          // **함께** 넣어야 심사를 통과시킨다(App Store Review 4.8). 그래서
          // 지금은 다른 버튼들과 같은 스위치로 함께 감춰둔다.
          SocialButton(
            label: 'Apple로 시작하기',
            background: Colors.black,
            textColor: Colors.white,
            radius: _buttonRadius,
            badge: const Icon(Icons.apple, color: Colors.white, size: 24),
            onPressed: () => _start(context, ref, guest: false),
          ),
          const SizedBox(height: 12),
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
        ],
        SocialButton(
          // 소셜 버튼이 없을 땐 이게 유일한 진입 버튼이라 '비회원'을 떼고 부른다.
          label: kSocialLoginEnabled ? '비회원으로 시작하기' : '시작하기',
          background: AppColors.guest,
          textColor: Colors.white,
          radius: _buttonRadius,
          badge: const SizedBox(width: 24),
          onPressed: () => _start(context, ref, guest: true),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => showPrivacyPolicy(context),
          child: Text(
            '개인정보처리방침',
            style:
                AppText.body(
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
  );
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
