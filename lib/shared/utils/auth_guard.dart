import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pixel_theme.dart';
import '../../features/pet/application/pet_providers.dart';

/// 로그인이 필요한 동작(아이템 구매 등)에 대한 가드.
///
/// - 회원이면 `true`를 반환 → 동작을 그대로 진행한다.
/// - 비회원이면 안내 다이얼로그를 띄우고 `false`를 반환한다.
///   ("로그인하기" 선택 시 로그인 화면으로 이동)
///
/// 사용 예:
/// ```dart
/// onPressed: () async {
///   if (!await ensureLoggedIn(context, ref)) return;
///   // ↓ 회원만 도달: 실제 구매 처리
///   buyItem(item);
/// }
/// ```
Future<bool> ensureLoggedIn(
  BuildContext context,
  WidgetRef ref, {
  String message = '아이템 구매는 로그인 후 이용할 수 있어요.',
}) async {
  final isGuest = ref.read(isGuestProvider);
  if (!isGuest) return true;

  final goLogin = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('로그인이 필요해요', style: AppText.pixel(size: 20)),
      content: Text(
        message,
        style: AppText.body(size: 14, color: AppColors.subtle),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('닫기',
              style: AppText.body(size: 14, color: AppColors.subtle)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('로그인하기',
              style: AppText.body(
                  size: 14,
                  color: AppColors.primary,
                  weight: FontWeight.w700)),
        ),
      ],
    ),
  );

  if (goLogin == true && context.mounted) {
    context.push('/login');
  }
  return false;
}
