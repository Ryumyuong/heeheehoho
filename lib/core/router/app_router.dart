import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/splash_page.dart';
import '../../features/onboarding/presentation/login_page.dart';
import '../../features/onboarding/presentation/has_pet_page.dart';
import '../../features/onboarding/presentation/photo_page.dart';
import '../../features/onboarding/presentation/scan_page.dart';
import '../../features/onboarding/presentation/customize_page.dart';
import '../../features/onboarding/presentation/info_page.dart';
import '../../features/onboarding/presentation/signup_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/home/presentation/placeholder_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashPage()),
    GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
    GoRoute(path: '/has-pet', builder: (c, s) => const HasPetPage()),
    GoRoute(path: '/photo', builder: (c, s) => const PhotoPage()),
    GoRoute(path: '/scan', builder: (c, s) => const ScanPage()),
    GoRoute(path: '/customize', builder: (c, s) => const CustomizePage()),
    GoRoute(path: '/info', builder: (c, s) => const InfoPage()),
    GoRoute(path: '/signup', builder: (c, s) => const SignupPage()),

    // 하단 탭 셸: 산책 / 커뮤니티 / 홈(중앙) / 기부 / 스토어
    // (홈만 구현, 나머지는 placeholder)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navShell) => MainShell(navShell: navShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/walk',
            builder: (c, s) =>
                const PlaceholderPage(title: '산책', icon: Icons.pets),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/community',
            builder: (c, s) => const PlaceholderPage(
                title: '커뮤니티', icon: Icons.chat_bubble_outline),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomePage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/donate',
            builder: (c, s) =>
                const PlaceholderPage(title: '기부', icon: Icons.favorite_border),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/store',
            builder: (c, s) => const PlaceholderPage(
                title: '스토어', icon: Icons.storefront_outlined),
          ),
        ]),
      ],
    ),
  ],
);
