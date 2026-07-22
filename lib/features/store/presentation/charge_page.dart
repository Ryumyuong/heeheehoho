import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';
import '../../pet/application/pet_providers.dart';
import '../application/iap_providers.dart';
import '../domain/paw_product.dart';

/// 발자국 충전(구글 인앱결제) 페이지.
class ChargePage extends ConsumerWidget {
  const ChargePage({super.key});

  double _hPad(BuildContext context) => DesignScale.scaled(context, 28);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paws = ref.watch(petProvider)?.paws ?? 0;
    final iap = ref.watch(iapProvider);
    final topPad = MediaQuery.of(context).padding.top;

    // 결제 성공/실패 스낵바.
    ref.listen(iapProvider, (prev, next) {
      if (next.lastGrantedPaws != null &&
          prev?.lastGrantedPaws != next.lastGrantedPaws) {
        _snack(context, '발자국 ${_comma(next.lastGrantedPaws!)}개를 충전했어요!');
        ref.read(iapProvider.notifier).clearGranted();
      }
      if (next.error != null && prev?.error != next.error) {
        _snack(context, next.error!);
        ref.read(iapProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: Column(
        children: [
          // 오렌지 헤더 + 뒤로가기 + 현재 발자국.
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
                      context.canPop() ? context.pop() : context.go('/store'),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '발자국 충전',
                    style: AppText.body(
                      family: 'Pretendard',
                      size: 23,
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(500),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/icons/paw.png',
                          width: 18, height: 18,
                          filterQuality: FilterQuality.none),
                      const SizedBox(width: 6),
                      Text(
                        _comma(paws),
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  _hPad(context), 20, _hPad(context), 24),
              children: [
                Text(
                  '필요한 만큼 발자국을 충전하세요',
                  style: AppText.body(size: 14, color: AppColors.subtle),
                ),
                const SizedBox(height: 16),
                for (final p in kPawProducts) ...[
                  _ProductRow(
                    product: p,
                    price: iap.priceFor(p),
                    loading: iap.purchasing == p.id,
                    onBuy: () => ref.read(iapProvider.notifier).buy(p),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!iap.available) ...[
                  const SizedBox(height: 8),
                  Text(
                    '결제는 Play 스토어에서 설치한 앱에서만 동작해요. '
                    '(내부 테스트 포함)',
                    style: AppText.body(size: 12, color: AppColors.subtle),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  '· 발자국은 소모성 상품이며 환불/복구되지 않습니다.\n'
                  '· 결제는 Google Play를 통해 진행됩니다.',
                  style: AppText.body(
                    size: 11,
                    color: AppColors.subtle,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg,
              style: AppText.body(size: 13, color: Colors.white)),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.price,
    required this.loading,
    required this.onBuy,
  });

  final PawProduct product;
  final String price;
  final bool loading;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0E8DE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Image.asset('assets/icons/paw.png',
              width: 30, height: 30, filterQuality: FilterQuality.none),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '발자국 ${_comma(product.paws)}개',
              style: AppText.body(size: 16, weight: FontWeight.w800),
            ),
          ),
          GestureDetector(
            onTap: loading ? null : onBuy,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minWidth: 92),
              height: 38,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      price,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String _comma(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
