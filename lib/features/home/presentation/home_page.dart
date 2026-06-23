import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/presentation/widgets/dog_sprite.dart';
import '../domain/room_item.dart';
import 'widgets/room_painters.dart';
import 'widgets/stat_card.dart';
import 'widgets/item_panel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  // 강아지가 걸을 때만 돌아가는 컨트롤러(배경 패럴랙스 스크롤).
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  bool _walking = false;
  bool _itemOpen = false;
  String? _pendingItem; // 배치 미리보기 중인 아이템 id
  static const double _worldRange = 700;

  @override
  void dispose() {
    _walk.dispose();
    super.dispose();
  }

  void _toggleWalk() {
    if (_itemOpen) return;
    setState(() => _walking = !_walking);
    _walking ? _walk.repeat() : _walk.stop();
  }

  void _toggleItemPanel() {
    setState(() {
      _itemOpen = !_itemOpen;
      if (_itemOpen) {
        _walking = false;
        _walk.stop();
      } else {
        _pendingItem = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petProvider);
    final name = pet?.name ?? '세미';
    final points = pet?.points ?? 1250;
    final equipped = pet?.equippedItems ?? const [];
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.splashOrange,
      body: Stack(
        children: [
          // ── 방 (벽+창문 / 바닥) : 패럴랙스 ──
          AnimatedBuilder(
            animation: _walk,
            builder: (context, _) {
              final u = _walk.value * 2;
              final tri = u <= 1 ? u : 2 - u;
              final camX = tri * _worldRange;
              return Column(
                children: [
                  Expanded(
                    child: CustomPaint(
                      painter: WallPainter(camX * 0.55),
                      size: Size.infinite,
                    ),
                  ),
                  SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: CustomPaint(painter: FloorPainter(camX)),
                  ),
                ],
              );
            },
          ),

          // ── 배치된 가구 (placeholder 아이콘) ──
          ..._buildPlacedFurniture(equipped, topPad),

          // ── 강아지 (탭=산책 토글) + 장착 웨어러블 ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 150,
            child: Center(
              child: AnimatedBuilder(
                animation: _walk,
                builder: (context, child) {
                  final facingRight = _walk.value * 2 <= 1;
                  return GestureDetector(
                    onTap: _toggleWalk,
                    child: _DogWithWearables(
                      walking: _walking,
                      flip: _walking && !facingRight,
                      equipped: equipped,
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 말풍선 ──
          Positioned(
            top: topPad + 210,
            left: 60,
            child: _SpeechBubble(_walking ? '같이 산책 가자멍!' : '보고싶었다멍!'),
          ),

          // ── 상단 오렌지 바 (미니룸 타이틀 / 포인트·알림) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topPad + 56,
              color: AppColors.splashOrange,
              padding: EdgeInsets.only(top: topPad, left: 20, right: 18),
              child: Row(
                children: [
                  Text('$name의 미니룸',
                      style: AppText.pixel(size: 16, color: Colors.white)),
                  const Spacer(),
                  const Icon(Icons.circle, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(_comma(points),
                      style: AppText.body(
                          size: 16,
                          color: Colors.white,
                          weight: FontWeight.w700)),
                  const SizedBox(width: 16),
                  const Icon(Icons.notifications_none,
                      color: Colors.white, size: 22),
                ],
              ),
            ),
          ),

          // ── 스탯 카드 (좌상단) ──
          Positioned(
            top: topPad + 68,
            left: 16,
            child: StatCard(
              happiness: pet?.happiness ?? 70,
              hunger: pet?.hunger ?? 60,
              fatigue: pet?.fatigue ?? 40,
            ),
          ),

          // ── 액션 버튼 (우상단) ──
          Positioned(
            top: topPad + 68,
            right: 16,
            child: _ActionButtons(
              onFeed: () => ref.read(petProvider.notifier).feed(),
              onSleep: () => ref.read(petProvider.notifier).sleep(),
              onPlay: () => ref.read(petProvider.notifier).play(),
            ),
          ),

          // ── 액자 등 가구 배치 미리보기 (X / ✓) ──
          if (_pendingItem != null)
            Positioned(
              top: topPad + 150,
              right: 40,
              child: _PlacementPreview(
                item: kRoomItems.firstWhere((e) => e.id == _pendingItem),
                onCancel: () => setState(() => _pendingItem = null),
                onConfirm: () {
                  ref.read(petProvider.notifier).toggleItem(_pendingItem!);
                  setState(() => _pendingItem = null);
                },
              ),
            ),

          // ── ITEM 버튼 ──
          Positioned(
            right: 16,
            bottom: _itemOpen ? 286 : 16,
            child: ItemToggleButton(open: _itemOpen, onTap: _toggleItemPanel),
          ),

          // ── 아이템 패널 ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: _itemOpen ? 0 : -300,
            child: ItemPanel(
              equipped: equipped,
              pending: _pendingItem,
              onSelect: (item) {
                if (!item.enabled) return;
                if (item.category == ItemCategory.furniture) {
                  setState(() => _pendingItem = item.id);
                } else {
                  ref.read(petProvider.notifier).toggleItem(item.id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlacedFurniture(List<String> equipped, double topPad) {
    final spots = <String, Offset>{
      'wood_table': const Offset(40, 0.62),
      'stand_lamp': const Offset(0.0, 0.55),
      'plant': const Offset(0.0, 0.62),
      'frame': const Offset(0.0, 0.0),
    };
    final out = <Widget>[];
    final placed =
        equipped.where((id) => spots.containsKey(id)).toList();
    for (var i = 0; i < placed.length; i++) {
      final item = kRoomItems.firstWhere((e) => e.id == placed[i]);
      out.add(Positioned(
        left: 24 + i * 56,
        bottom: 150,
        child: _FurniturePlaceholder(item: item),
      ));
    }
    return out;
  }

  static String _comma(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

/// 강아지 + 장착 웨어러블(아이콘 placeholder) 오버레이.
class _DogWithWearables extends StatelessWidget {
  const _DogWithWearables({
    required this.walking,
    required this.flip,
    required this.equipped,
  });
  final bool walking;
  final bool flip;
  final List<String> equipped;

  @override
  Widget build(BuildContext context) {
    final wearables = kRoomItems
        .where((e) =>
            e.category == ItemCategory.wearable && equipped.contains(e.id))
        .toList();
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DogSprite(
            frames: walking ? DogFrames.walk : DogFrames.idle,
            fps: walking ? 8 : 6,
            flip: flip,
            size: 130,
          ),
          // 웨어러블 placeholder (실제 픽셀 에셋 준비 시 위치 맞춰 교체)
          for (var i = 0; i < wearables.length; i++)
            Positioned(
              top: 6 + i * 22.0,
              child: Icon(wearables[i].icon,
                  color: AppColors.coral, size: 20),
            ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onFeed,
    required this.onSleep,
    required this.onPlay,
  });
  final VoidCallback onFeed;
  final VoidCallback onSleep;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ActionPill(emoji: '🍰', label: '밥주기', onTap: onFeed),
        const SizedBox(height: 10),
        _ActionPill(emoji: '🌙', label: '잠자기', onTap: onSleep),
        const SizedBox(height: 10),
        _ActionPill(emoji: '🎾', label: '놀아주기', onTap: onPlay),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill(
      {required this.emoji, required this.label, required this.onTap});
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(label,
                  style: AppText.body(size: 13, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FurniturePlaceholder extends StatelessWidget {
  const _FurniturePlaceholder({required this.item});
  final RoomItem item;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, color: AppColors.brownIcon, size: 40),
      ],
    );
  }
}

class _PlacementPreview extends StatelessWidget {
  const _PlacementPreview({
    required this.item,
    required this.onCancel,
    required this.onConfirm,
  });
  final RoomItem item;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RoundIcon(Icons.close, AppColors.subtle, onCancel),
            const SizedBox(width: 60),
            _RoundIcon(Icons.check, AppColors.primary, onConfirm),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, size: 44, color: AppColors.brownIcon),
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon, this.color, this.onTap);
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(text,
              style: AppText.body(size: 13, weight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: CustomPaint(size: const Size(14, 8), painter: _TailPainter()),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
