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
    // 하단바에 붙어 있어서 위쪽 모서리만 둥글다(radius 10).
    const radius = BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
    );
    return Material(
      color: AppColors.primary,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                  open
                      ? 'assets/icons/item_arrow_down.png'
                      : 'assets/icons/item_arrow_up.png',
                  width: 18,
                  height: 18,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn),
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
class ItemPanel extends StatefulWidget {
  const ItemPanel({
    super.key,
    required this.equipped,
    required this.owned,
    required this.pending,
    required this.onSelect,
  });

  final List<String> equipped;
  final Set<String> owned; // 보유(구매)한 아이템 id. 미보유는 잠금.
  final String? pending;
  final ValueChanged<RoomItem> onSelect;

  @override
  State<ItemPanel> createState() => _ItemPanelState();
}

class _ItemPanelState extends State<ItemPanel> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F2), // 아이템창 상세 배경색
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: GridView.count(
          controller: _scroll,
          crossAxisCount: 4,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.92,
          children: [
            for (final item in kRoomItems)
              _ItemCell(
                item: item,
                locked: !widget.owned.contains(item.id),
                selected:
                    widget.pending == item.id || widget.equipped.contains(item.id),
                onTap: () => widget.onSelect(item),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemCell extends StatelessWidget {
  const _ItemCell({
    required this.item,
    required this.locked,
    required this.selected,
    required this.onTap,
  });
  final RoomItem item;
  final bool locked; // 미보유 = 잠금(회색, 선택 불가)
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = locked;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                // 선택 시 #F4845F, 기본 #EDE9E1, 1.5px.
                color: selected
                    ? const Color(0xFFF4845F)
                    : const Color(0xFFEDE9E1),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    // 이미지를 칸보다 조금 작게 — 흰 칸 안에 여유를 두되 너무 작지 않게.
                    child: FractionallySizedBox(
                      widthFactor: 0.86,
                      heightFactor: 0.86,
                      child: item.asset != null
                          ? Image.asset(
                              item.asset!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                            )
                          : FittedBox(
                              fit: BoxFit.contain,
                              child: Icon(item.icon,
                                  color: item.category == ItemCategory.wearable
                                      ? AppColors.coral
                                      : AppColors.brownIcon),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          // 미보유(잠금) 아이템: #FEFEFE 67% 오버레이로 뿌옇게 + 자물쇠 + 선택 불가.
          if (disabled)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: const Color(0xFFFEFEFE).withValues(alpha: 0.67),
                    alignment: Alignment.center,
                    child: const Icon(Icons.lock,
                        size: 18, color: AppColors.subtle),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
