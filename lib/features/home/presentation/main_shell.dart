import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';

/// 하단 5탭 셸. 홈만 구현, 나머지는 placeholder.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navShell});
  final StatefulNavigationShell navShell;

  static const _items = [
    (icon: Icons.pets, label: '산책'),
    (icon: Icons.chat_bubble_outline, label: '커뮤니티'),
    (icon: Icons.home_filled, label: '홈'),
    (icon: Icons.favorite_border, label: '기부'),
    (icon: Icons.storefront_outlined, label: '스토어'),
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
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.subtle;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.body(
              size: 10,
              color: color,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
