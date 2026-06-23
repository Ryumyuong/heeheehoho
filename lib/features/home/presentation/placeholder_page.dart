import 'package:flutter/material.dart';
import '../../../core/theme/pixel_theme.dart';

/// 디자인 미정 탭(산책/커뮤니티/입양·기부/마이페이지) 자리표시.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primarySoft),
            const SizedBox(height: 16),
            Text(title, style: AppText.pixel(size: 24)),
            const SizedBox(height: 10),
            Text('준비 중이에요 🐾',
                style: AppText.body(size: 14, color: AppColors.subtle)),
          ],
        ),
      ),
    );
  }
}
