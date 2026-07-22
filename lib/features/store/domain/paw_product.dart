/// 발자국 구매 상품(구글 인앱결제 소모성 상품).
///
/// [id]는 Play Console의 인앱 상품 ID와 **정확히 같아야** 한다.
/// 가격은 스토어(구글)에서 받아오는 값을 쓰고, [fallbackPrice]는 로드 전/실패 시
/// 임시로 보여줄 원화 표기다.
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

/// 판매 상품 목록. 10개 100원 / 100개 1,000원 / 1,000개 10,000원.
const List<PawProduct> kPawProducts = [
  PawProduct(id: 'paws_10', paws: 10, fallbackPrice: '₩100'),
  PawProduct(id: 'paws_100', paws: 100, fallbackPrice: '₩1,000'),
  PawProduct(id: 'paws_1000', paws: 1000, fallbackPrice: '₩10,000'),
];

Set<String> get kPawProductIds => kPawProducts.map((e) => e.id).toSet();

PawProduct? pawProductForId(String id) {
  for (final p in kPawProducts) {
    if (p.id == id) return p;
  }
  return null;
}
