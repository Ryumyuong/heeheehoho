/// 마켓 상품 = 뼈다귀로 사는 실제 물품.
///
/// 미니룸 아이템([RoomItem])이 발자국으로 사는 가상 아이템인 것과 달리,
/// 마켓 상품은 뼈다귀를 써서 보호소의 실제 강아지에게 보내는 물건이다.
class MarketItem {
  const MarketItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.bones,
    this.badge,
    this.asset,
  });

  final String id;
  final String name;

  /// 브랜드·설명 한 줄. 예) '네이처스베스트 · 100% 자연 원료 무첨가'
  final String subtitle;

  /// 구매에 필요한 뼈다귀 개수.
  final int bones;

  /// '베스트셀러', '이번 주 추천' 같은 강조 뱃지.
  final String? badge;

  /// 상품 사진. 없으면 카드가 회색 자리표시자를 그린다.
  final String? asset;
}

/// 마켓에 진열되는 상품. 실제 서비스에서는 서버에서 받아올 목록이다.
const List<MarketItem> kMarketItems = [
  MarketItem(
    id: 'grainfree_food',
    name: '오리지널 그레인프리 사료',
    subtitle: '네이처스베스트 · 100% 자연 원료 무첨가',
    bones: 5,
    badge: '베스트셀러',
    asset: 'assets/market/food_grainfree.png',
  ),
  MarketItem(
    id: 'chicken_jerky',
    name: '닭가슴살 저키',
    subtitle: '도그윗 단백질 고함량 건강간식',
    bones: 5,
    badge: '이번 주 추천',
    asset: 'assets/market/jerky_chicken.png',
  ),
];

/// 이번 달 기부 캠페인. 마켓 상단에 진행률과 함께 노출된다.
class DonationCampaign {
  const DonationCampaign({
    required this.title,
    required this.rescued,
    required this.goal,
    required this.bonesToJoin,
  });

  final String title;

  /// 지금까지 구조 완료한 마릿수.
  final int rescued;
  final int goal;

  /// 캠페인에 참여할 때 쓰는 뼈다귀 개수.
  final int bonesToJoin;

  double get progress => goal == 0 ? 0 : (rescued / goal).clamp(0, 1);

  /// 진행률·게이지·구조 마릿수는 모두 [rescued] 하나에서 나온다.
  /// 참여할 때 이 값만 올리면 셋이 함께 움직인다.
  DonationCampaign withRescued(int value) => DonationCampaign(
    title: title,
    rescued: value.clamp(0, goal),
    goal: goal,
    bonesToJoin: bonesToJoin,
  );
}

const kCampaign = DonationCampaign(
  title: '작은 발걸음이 모여 기적이 되는 공간',
  rescued: 2341,
  goal: 3500,
  bonesToJoin: 5,
);
