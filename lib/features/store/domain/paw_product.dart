import 'package:flutter/foundation.dart';

/// 발자국 구매 상품(인앱결제 소모성 상품).
///
/// [id]는 스토어 콘솔의 인앱 상품 ID와 **정확히 같아야** 한다.
/// Play Console과 App Store Connect의 ID 규칙이 달라서 상품 목록을 플랫폼별로
/// 나눠 둔다. 가격은 스토어에서 받아오는 값을 쓰고, [fallbackPrice]는 로드 전/
/// 실패 시 임시로 보여줄 원화 표기다.
class PawProduct {
  const PawProduct({
    required this.id,
    required this.paws,
    required this.fallbackPrice,
  });

  final String id;
  final int paws;
  final String fallbackPrice;
}

/// Android(Play Console) 상품. 10개 100원 / 100개 1,000원 / 1,000개 10,000원.
const List<PawProduct> kAndroidPawProducts = [
  PawProduct(id: 'paws_10', paws: 10, fallbackPrice: '₩100'),
  PawProduct(id: 'paws_100', paws: 100, fallbackPrice: '₩1,000'),
  PawProduct(id: 'paws_1000', paws: 1000, fallbackPrice: '₩10,000'),
];

/// iOS(App Store Connect) 상품.
///
/// 애플 한국 스토어의 최저 가격대가 ₩1,100이라 Android의 ₩100짜리 최소 상품을
/// 그대로 만들 수 없다. 그래서 같은 가격대에 발자국을 10배로 담아 발자국당
/// 단가(₩11)를 Android(₩10)에 맞췄다. 상품 수는 Android보다 하나 적다.
const List<PawProduct> kIosPawProducts = [
  PawProduct(
      id: 'com.heeheehoho.app.paw.100', paws: 100, fallbackPrice: '₩1,100'),
  PawProduct(
      id: 'com.heeheehoho.app.paw.1000', paws: 1000, fallbackPrice: '₩11,000'),
];

/// 지금 플랫폼에서 판매하는 상품 목록.
List<PawProduct> get kPawProducts {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    return kIosPawProducts;
  }
  return kAndroidPawProducts;
}

Set<String> get kPawProductIds => kPawProducts.map((e) => e.id).toSet();

/// 결제 완료된 상품 ID로 지급할 발자국을 찾는다.
///
/// 스토어가 돌려주는 ID는 그 플랫폼 것이지만, 플랫폼 판정이 어긋나도 지급을
/// 놓치지 않도록 양쪽 목록을 모두 뒤진다.
PawProduct? pawProductForId(String id) {
  for (final p in [...kAndroidPawProducts, ...kIosPawProducts]) {
    if (p.id == id) return p;
  }
  return null;
}
