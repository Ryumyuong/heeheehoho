import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../pet/application/pet_providers.dart';
import '../domain/paw_product.dart';

/// 발자국 인앱결제 컨트롤러.
///
/// 구글 결제(구매 완료)까지 성공하면 발자국을 지급하고 소비(consume) 처리한다.
/// Play Console에 상품이 아직 없거나 스토어를 못 쓰는 환경(웹·에뮬레이터 일부)에서는
/// [available]가 false가 되고, 화면은 임시 가격만 보여준다.
class IapState {
  const IapState({
    this.available = false,
    this.products = const {},
    this.purchasing,
    this.lastGrantedPaws,
    this.error,
  });

  /// 스토어 결제를 쓸 수 있는지.
  final bool available;

  /// 상품ID → 스토어에서 받은 상품 정보(가격 문자열 포함).
  final Map<String, ProductDetails> products;

  /// 지금 결제 진행 중인 상품 ID(있으면 로딩 표시).
  final String? purchasing;

  /// 방금 지급한 발자국(성공 스낵바용). 소비하면 null로 되돌린다.
  final int? lastGrantedPaws;

  final String? error;

  IapState copyWith({
    bool? available,
    Map<String, ProductDetails>? products,
    String? purchasing,
    bool clearPurchasing = false,
    int? lastGrantedPaws,
    bool clearGranted = false,
    String? error,
    bool clearError = false,
  }) => IapState(
    available: available ?? this.available,
    products: products ?? this.products,
    purchasing: clearPurchasing ? null : (purchasing ?? this.purchasing),
    lastGrantedPaws: clearGranted ? null : (lastGrantedPaws ?? this.lastGrantedPaws),
    error: clearError ? null : (error ?? this.error),
  );

  /// 상품별 표시 가격(스토어 값 우선, 없으면 임시 원화).
  String priceFor(PawProduct p) =>
      products[p.id]?.price ?? p.fallbackPrice;
}

class IapController extends Notifier<IapState> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  IapState build() {
    ref.onDispose(() => _sub?.cancel());
    // 웹에서는 인앱결제를 쓰지 않는다.
    if (!kIsWeb) {
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (e) => state = state.copyWith(error: '$e'),
      );
      Future.microtask(_init);
    }
    return const IapState();
  }

  Future<void> _init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      state = state.copyWith(available: false);
      return;
    }
    final resp = await _iap.queryProductDetails(kPawProductIds);
    final map = {for (final p in resp.productDetails) p.id: p};
    state = state.copyWith(available: true, products: map);
    // 앱 시작 시 밀린(완료 안 된) 구매를 복원해 지급한다.
    await _iap.restorePurchases();
  }

  /// 발자국 상품 구매 시작.
  Future<void> buy(PawProduct product) async {
    if (state.purchasing != null) return;
    final details = state.products[product.id];
    if (details == null) {
      state = state.copyWith(error: '상품을 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
      return;
    }
    state = state.copyWith(purchasing: product.id, clearError: true);
    final param = PurchaseParam(productDetails: details);
    // 발자국은 소모성 상품이라 consumable 구매로 요청한다.
    await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grant(p);
        case PurchaseStatus.error:
          state = state.copyWith(
            clearPurchasing: true,
            error: p.error?.message ?? '결제에 실패했어요.',
          );
        case PurchaseStatus.canceled:
          state = state.copyWith(clearPurchasing: true);
        case PurchaseStatus.pending:
          break;
      }
      // 완료된 거래는 반드시 completePurchase로 닫아야 다음 결제가 된다.
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  /// 결제 완료 → 발자국 지급.
  ///
  /// 지금은 클라이언트에서 바로 지급한다. 실제 서비스에서는 구글 영수증을
  /// **서버에서 검증**한 뒤 지급하는 게 안전하다(위·변조 방지).
  Future<void> _grant(PurchaseDetails p) async {
    final product = pawProductForId(p.productID);
    if (product == null) return;
    await ref.read(petProvider.notifier).addPaws(product.paws);
    state = state.copyWith(
      clearPurchasing: true,
      lastGrantedPaws: product.paws,
    );
  }

  void clearGranted() => state = state.copyWith(clearGranted: true);
  void clearError() => state = state.copyWith(clearError: true);
}

final iapProvider = NotifierProvider<IapController, IapState>(IapController.new);
