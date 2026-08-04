import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';
import '../../../shared/widgets/wallet_chip.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/domain/dog_appearance.dart';
import '../../pet/presentation/widgets/dog_with_wearables.dart';

/// 프로필 화면 좌우 여백. 시안(412px)에서 28px이고, 폭이 달라지면 함께 늘고 준다.
double _hPad(BuildContext context) => DesignScale.scaled(context, 28);

String _comma(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// 프로필: 내 네발 친구 요약 + 로그아웃.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '로그아웃할까요?',
          style: AppText.body(size: 16, weight: FontWeight.w800),
        ),
        content: Text(
          '네발 친구와 아이템은 그대로 남아 있어요.',
          style: AppText.body(size: 13, color: AppColors.subtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '취소',
              style: AppText.body(size: 14, color: AppColors.subtle),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '로그아웃',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    // 세션만 끊는다(펫·아이템 데이터는 유지). 온보딩 초안도 비워 새로 시작하게.
    await ref.read(isGuestProvider.notifier).setGuest(false);
    ref.read(onboardingProvider.notifier).restart();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(petProvider);
    final isGuest = ref.watch(isGuestProvider);
    final appearance = pet == null
        ? const DogAppearance()
        : DogAppearance.fromPet(pet);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: Column(
        children: [
          _Header(
            paws: pet?.paws ?? 0,
            bones: pet?.bones ?? 0,
            topPad: topPad,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(_hPad(context), 24, _hPad(context), 24),
              children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFEDE9E1), width: 1.4),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: DogWithWearables(
                        equipped: pet?.equippedItems ?? const [],
                        appearance: appearance,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet?.name ?? '네발 친구가 없어요',
                          style: AppText.body(
                            size: 16,
                            weight: FontWeight.w800,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isGuest ? '비회원으로 이용 중' : '회원',
                          style: AppText.body(
                            size: 12,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _MenuTile(
              label: '미니게임',
              icon: Icons.sports_esports,
              onTap: () => context.push('/games'),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              label: '로그아웃',
              icon: Icons.logout,
              onTap: () => _logout(context, ref),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 상단 오렌지 헤더 (산책·스토어와 동일) ──
class _Header extends StatelessWidget {
  const _Header({required this.paws, required this.bones, required this.topPad});

  final int paws;
  final int bones;
  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: topPad + 62,
        left: _hPad(context),
        right: _hPad(context),
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '프로필',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                family: 'Pretendard',
                size: 23,
                color: Colors.white,
                weight: FontWeight.w800,
              ),
            ),
          ),
          WalletChip.paws(
            _comma(paws),
            onTap: () => context.push('/charge'),
          ),
          // 마켓이 닫혀 있는 동안 뼈다귀는 감춘다(kBonesEnabled).
          if (kBonesEnabled) ...[
            const SizedBox(width: 8),
            WalletChip.bones(_comma(bones)),
          ],
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go('/store'),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFC6F00),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/icons/cart.png',
                width: 18,
                height: 18,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFEDE9E1), width: 1.4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF888888)),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w700,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(0xFFCCBFB5),
            ),
          ],
        ),
      ),
    );
  }
}
