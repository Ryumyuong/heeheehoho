import 'package:flutter/material.dart';

enum ItemCategory { furniture, wearable }

/// 미니룸 아이템 (가구/웨어러블).
///
/// 픽셀 아이템 이미지가 준비되면 [asset]에 경로를 채우고
/// 홈에서 Image.asset으로 렌더하도록 교체하세요. (현재는 [icon]로 표시)
class RoomItem {
  const RoomItem({
    required this.id,
    required this.label,
    required this.category,
    required this.icon,
    this.enabled = true,
    this.asset,
  });

  final String id;
  final String label;
  final ItemCategory category;
  final IconData icon;
  final bool enabled; // false = 잠금/준비중(회색)
  final String? asset;
}

/// 아이템 카탈로그 (image 13 기준).
const List<RoomItem> kRoomItems = [
  // 가구
  RoomItem(id: 'wood_table', label: '우드테이블', category: ItemCategory.furniture, icon: Icons.table_restaurant),
  RoomItem(id: 'stand_lamp', label: '스탠드 조명', category: ItemCategory.furniture, icon: Icons.light),
  RoomItem(id: 'plant', label: '화분', category: ItemCategory.furniture, icon: Icons.local_florist),
  RoomItem(id: 'frame', label: '액자', category: ItemCategory.furniture, icon: Icons.photo),
  // 웨어러블
  RoomItem(id: 'heart_glasses', label: '하트안경', category: ItemCategory.wearable, icon: Icons.favorite),
  RoomItem(id: 'crown', label: '왕관모자', category: ItemCategory.wearable, icon: Icons.workspace_premium),
  RoomItem(id: 'sky_ribbon', label: '하늘색 리본', category: ItemCategory.wearable, icon: Icons.bookmark, enabled: false),
  RoomItem(id: 'green_scarf', label: '초록 스카프', category: ItemCategory.wearable, icon: Icons.dry_cleaning),
];
