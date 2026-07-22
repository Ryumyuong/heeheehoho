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
    this.price = 500,
  });

  final String id;
  final String label;
  final ItemCategory category;
  final IconData icon;
  final bool enabled; // false = 잠금/준비중(회색)
  final String? asset;
  final int price; // 스토어 가격(P)
}

/// 아이템 카탈로그 (image 13 기준). 픽셀 에셋은 `assets/items/{id}.png`.
const List<RoomItem> kRoomItems = [
  // 가구
  RoomItem(
    id: 'wood_table',
    label: '우드테이블',
    category: ItemCategory.furniture,
    icon: Icons.table_restaurant,
    asset: 'assets/items/wood_table.png',
  ),
  RoomItem(
    id: 'stand_lamp',
    label: '스탠드 조명',
    category: ItemCategory.furniture,
    icon: Icons.light,
    asset: 'assets/items/stand_lamp.png',
  ),
  RoomItem(
    id: 'plant',
    label: '화분',
    category: ItemCategory.furniture,
    icon: Icons.local_florist,
    asset: 'assets/items/plant.png',
  ),
  RoomItem(
    id: 'frame',
    label: '액자',
    category: ItemCategory.furniture,
    icon: Icons.photo,
    asset: 'assets/items/frame.png',
  ),
  // 웨어러블
  RoomItem(
    id: 'heart_glasses',
    label: '하트안경',
    category: ItemCategory.wearable,
    icon: Icons.favorite,
    asset: 'assets/items/heart_glasses.png',
  ),
  RoomItem(
    id: 'crown',
    label: '왕관모자',
    category: ItemCategory.wearable,
    icon: Icons.workspace_premium,
    asset: 'assets/items/crown.png',
  ),
  RoomItem(
    id: 'sky_ribbon',
    label: '하늘색 리본',
    category: ItemCategory.wearable,
    icon: Icons.bookmark,
    enabled: false,
    asset: 'assets/items/sky_ribbon.png',
  ),
  RoomItem(
    id: 'green_scarf',
    label: '초록 스카프',
    category: ItemCategory.wearable,
    icon: Icons.dry_cleaning,
    asset: 'assets/items/green_scarf.png',
  ),
];

/// 머리에 쓰는 웨어러블 — 이 중 하나만 착용할 수 있다.
/// 홈(실제 착용)과 스토어(입어보기)가 같은 규칙을 쓰도록 여기서 한 번만 정의한다.
const Set<String> kHeadSlotItems = {'crown', 'sky_ribbon'};
