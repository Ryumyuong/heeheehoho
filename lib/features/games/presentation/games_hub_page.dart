import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';

double _hPad(BuildContext context) => DesignScale.scaled(context, 28);

/// 미니게임 허브: 게임 목록.
class GamesHubPage extends StatelessWidget {
  const GamesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: Column(
        children: [
          // 오렌지 헤더 + 뒤로가기
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: topPad + 62,
              left: _hPad(context),
              right: _hPad(context),
              bottom: 14,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/profile'),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '미니게임',
                  style: AppText.body(
                    family: 'Pretendard',
                    size: 23,
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(_hPad(context), 20, _hPad(context), 24),
              children: [
                _GameCard(
                  emoji: '⏱️',
                  title: '8.15초 맞추기',
                  desc: '달리는 강아지를 8.15초에 딱 멈춰라!',
                  gradient: const [Color(0xFFFFB56B), Color(0xFFFC7A6E)],
                  onTap: () => context.push('/games/timer'),
                ),
                const SizedBox(height: 14),
                _GameCard(
                  emoji: '🐶',
                  title: '강아지 얼굴 맞추기',
                  desc: '떨어지는 얼굴 파츠를 제자리에 딱 맞게!',
                  gradient: const [Color(0xFF8FD3C4), Color(0xFF5FB89E)],
                  onTap: () => context.push('/games/face'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.gradient,
    required this.onTap,
  });
  final String emoji;
  final String title;
  final String desc;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body(
                      size: 17,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    desc,
                    style: AppText.body(
                      size: 12.5,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
