import 'package:flutter/material.dart';

import '../../../../core/theme/pixel_theme.dart';
import '../../domain/community_models.dart';

/// 아바타(둥근 사각형 배경 + 이모지). [radius] 미지정 시 크기 비례.
class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    required this.neighbor,
    this.size = 44,
    this.radius,
  });

  final Neighbor neighbor;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.28;
    final url = neighbor.avatarUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: neighbor.avatarColor,
        child: (url != null && url.isNotEmpty)
            // 실제 프로필 사진. 로딩/실패 시 이모지로 폴백.
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Text(neighbor.emoji, style: TextStyle(fontSize: size * 0.5)),
              )
            : Text(neighbor.emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}

/// 상태 배지(산책 중/휴식 중/목욕 중/놀이 중).
/// 아이콘 + 회색 라벨. 배경색은 문맥에 따라 다르다(내 카드 #FFF8F0, 이웃 #F5F5F5).
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    this.background = const Color(0xFFF5F5F5),
    this.bold = false,
  });

  final PetStatus status;
  final Color background;
  final bool bold;

  static const _textColor = Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            status.iconAsset,
            width: 14,
            height: 14,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) =>
                Text(status.emoji, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: AppText.body(
              size: 12,
              weight: bold ? FontWeight.w700 : FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 게시글 하단 좋아요/댓글/공유 한 줄. 왼쪽부터 좋아요·댓글·공유.
///
/// 좋아요는 눌러서 토글(하트 채워짐 + 카운트 ±1)된다. 각 버튼은 탭을 소비해서
/// 상위 카드의 탭(게시물 상세 이동)으로 전파되지 않는다.
class PostStatsRow extends StatefulWidget {
  const PostStatsRow({
    super.key,
    required this.likes,
    required this.comments,
    required this.shares,
    this.onComment,
    this.onShare,
  });

  final int likes;
  final int comments;
  final int shares;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  State<PostStatsRow> createState() => _PostStatsRowState();
}

class _PostStatsRowState extends State<PostStatsRow> {
  static const _countColor = Color(0xFFBBBBBB);
  static const _coral = Color(0xFFF4845F);

  bool _liked = false;
  late int _likes = widget.likes;

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _stat(
          asset: 'assets/icons/ic_like.png',
          fallback: _liked ? Icons.favorite : Icons.favorite_border,
          count: _likes,
          active: _liked,
          onTap: _toggleLike,
          // 좋아요 상태일 땐 채워진 코랄 하트로.
          activeIcon: _liked
              ? const Icon(Icons.favorite, size: 20, color: _coral)
              : null,
        ),
        const SizedBox(width: 20),
        _stat(
          asset: 'assets/icons/ic_comment.png',
          fallback: Icons.chat_bubble_outline,
          count: widget.comments,
          onTap: widget.onComment,
        ),
        const SizedBox(width: 20),
        _stat(
          asset: 'assets/icons/ic_share.png',
          fallback: Icons.share_outlined,
          count: widget.shares,
          onTap: widget.onShare,
        ),
      ],
    );
  }

  Widget _stat({
    required String asset,
    required IconData fallback,
    required int count,
    VoidCallback? onTap,
    bool active = false,
    Widget? activeIcon,
  }) {
    final color = active ? _coral : _countColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // onTap이 있으면 그것으로 탭이 소비돼 카드 탭(상세 이동)으로 전파되지 않는다.
      onTap: onTap ?? () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          activeIcon ??
              Image.asset(
                asset,
                width: 20,
                height: 20,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) =>
                    Icon(fallback, size: 20, color: color),
              ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: AppText.body(
              size: 14,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 해시태그 묶음 — 알약형(배경 #FFF8F0, 글자 #F4845F).
class HashtagWrap extends StatelessWidget {
  const HashtagWrap({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '#$t',
              style: AppText.body(
                size: 12,
                weight: FontWeight.w700,
                color: const Color(0xFFF4845F),
              ),
            ),
          ),
      ],
    );
  }
}

/// 게시글 사진.
///
/// 우선순위: [imageUrl](Firebase Storage) → [imageAsset](번들) → 그라디언트+이모지.
/// 네트워크 이미지는 로딩 중엔 그라디언트를, 실패하면 플레이스홀더를 보여준다.
class CommunityPhoto extends StatelessWidget {
  const CommunityPhoto({
    super.key,
    this.imageUrl,
    this.imageAsset,
    required this.gradient,
    required this.emoji,
    this.radius = 16,
    this.aspectRatio = 1.5,
    this.emojiSize = 64,
  });

  /// 게시글에서 바로 받아 쓰는 편의 생성자.
  factory CommunityPhoto.of(
    Post post, {
    double radius = 16,
    double aspectRatio = 1.5,
    double emojiSize = 64,
  }) => CommunityPhoto(
    imageUrl: post.imageUrl,
    imageAsset: post.imageAsset,
    gradient: post.gradient,
    emoji: post.photoEmoji,
    radius: radius,
    aspectRatio: aspectRatio,
    emojiSize: emojiSize,
  );

  final String? imageUrl;
  final String? imageAsset;
  final List<Color> gradient;
  final String emoji;
  final double radius;
  final double aspectRatio;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: _image(),
      ),
    );
  }

  Widget _image() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return Image.asset(
        imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }
}
