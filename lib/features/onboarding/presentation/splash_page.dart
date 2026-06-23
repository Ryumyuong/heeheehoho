import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../pet/application/pet_providers.dart';

/// 스플래시: 주황 배경 + "귀엽다... / 나도 강아지...".
/// 잠깐 보여준 뒤 펫 존재 여부에 따라 홈/로그인으로 이동.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final hasPet = ref.read(petProvider) != null;
      context.go(hasPet ? '/home' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashOrange,
      body: Center(
        child: Text(
          '귀엽다...\n나도 강아지...',
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 16,
            color: Colors.white,
            weight: FontWeight.w600,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
