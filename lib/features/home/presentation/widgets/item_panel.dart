import 'package:flutter/material.dart';
import '../../../../core/theme/pixel_theme.dart';
import '../../domain/room_item.dart';

/// "▲ ITEM" / "▼ ITEM" 토글 버튼.
class ItemToggleButton extends StatelessWidget {
  const ItemToggleButton({super.key, required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: Colors.white, size: 18),
              const SizedBox(width: 2),
              Text('ITEM',
                  style: AppText.body(
                      size: 13, color: Colors.white, weight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하단 아이템 그리드 패널 (가구 + 웨어러블).
class ItemPanel extends StatelessWidget {
  const ItemPanel({
    super.key,
    required this.equipped,
    required this.pending,
    required this.onSelect,
  });

  final List<String> equipped;
  final String? pending;
  final ValueChanged<RoomItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final item in kRoomItems)
            _ItemCell(
              item: item,
              selected: pending == item.id || equipped.contains(item.id),
              onTap: () => onSelect(item),
            ),
        ],
      ),
    );
  }
}

class _ItemCell extends StatelessWidget {
  const _ItemCell({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final RoomItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !item.enabled;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF3F3F3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon,
                size: 30,
                color: disabled
                    ? AppColors.line
                    : (item.category == ItemCategory.wearable
                        ? AppColors.coral
                        : AppColors.brownIcon)),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 10,
                weight: FontWeight.w600,
                color: disabled ? AppColors.subtle : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
