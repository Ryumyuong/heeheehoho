import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// 홈 탭 인덱스(산책·커뮤니티·홈·스토어·프로필 중 홈).
  static const int _homeIndex = 2;

  @override
  Widget build(BuildContext context) {
    // 뒤로가기: 홈이 아닌 탭이면 홈 탭으로 돌아가고, 홈 탭이면 종료 확인창을 띄운다.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (navShell.currentIndex != _homeIndex) {
          navShell.goBranch(_homeIndex, initialLocation: true);
          return;
        }
        // 홈 탭에서 뒤로가기 → 종료 확인.
        final ctx = context;
        final exit = await _confirmExit(ctx);
        if (exit == true) SystemNavigator.pop();
      },
      child: _buildShell(context),
    );
  }

  Future<bool?> _confirmExit(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '앱을 종료할까요?',
          style: AppText.body(size: 16, weight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '취소',
              style: AppText.body(
                size: 14,
                color: AppColors.subtle,
                weight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '종료',
              style: AppText.body(
                size: 14,
                color: AppColors.primary,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShell(BuildContext context) {
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
