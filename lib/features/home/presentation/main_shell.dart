import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';

/// 하단 5탭 셸. 홈만 구현, 나머지는 placeholder.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navShell});
  final StatefulNavigationShell navShell;

  // 가운데 홈은 원형 컬러 버튼이라 글자도 틴트도 없다(label: null).
  static const _items = [
    (icon: 'assets/icons/nav_walk.png', label: '산책'),
    (icon: 'assets/icons/nav_community.png', label: '커뮤니티'),
    (icon: 'assets/icons/nav_home.png', label: null),
    (icon: 'assets/icons/nav_store.png', label: '스토어'),
    (icon: 'assets/icons/nav_profile.png', label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 12),
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _items[i].icon,
                        label: _items[i].label,
                        selected: navShell.currentIndex == i,
                        onTap: () => navShell.goBranch(
                          i,
                          initialLocation: i == navShell.currentIndex,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String icon; // 아이콘 png 에셋 경로
  final String? label; // null이면 홈(원형 컬러 버튼) — 글자 없음
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 선택 #F4845F / 미선택 #CCBFB5, 둘 다 Noto Sans KR 700 11px.
    final color = selected ? const Color(0xFFF4845F) : const Color(0xFFCCBFB5);
    final text = label;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (text == null)
            // 홈: 이미지 자체가 오렌지 원형 버튼이라 틴트하지 않는다.
            Image.asset(icon, width: 52, height: 52)
          else ...[
            // 단색 라인 아이콘을 선택/미선택 색으로 틴트.
            Image.asset(
              icon,
              width: 24,
              height: 24,
              color: color,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontVariations: [FontVariation('wght', 700)],
              ).copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}
