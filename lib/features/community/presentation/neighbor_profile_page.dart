import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';
import '../data/community_repository.dart';
import '../domain/community_models.dart';
import 'widgets/community_bits.dart';

double _hPad(BuildContext context) => DesignScale.scaled(context, 20);

const _line = Color(0xFFF0E8DE);
const _ink = Color(0xFF2D2D2D);
const _sub = Color(0xFFBBBBBB);

/// 이웃 프로필: 헤더(이름·이웃추가) + 통계 + 사진 그리드.
/// 이웃 목록/게시글의 닉네임을 누르면 진입.
class NeighborProfilePage extends ConsumerStatefulWidget {
  const NeighborProfilePage({super.key, required this.neighbor});
  final Neighbor neighbor;

  @override
  ConsumerState<NeighborProfilePage> createState() =>
      _NeighborProfilePageState();
}

class _NeighborProfilePageState extends ConsumerState<NeighborProfilePage> {
  bool _following = false;
  bool _uploadingAvatar = false;

  /// 내 프로필 사진 선택 → Storage 업로드 → 로컬 저장.
  Future<void> _pickAvatar() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 720,
    );
    if (x == null) return;
    final repo = ref.read(communityRepositoryProvider);
    if (!repo.available) {
      _snack('지금은 사진을 올릴 수 없어요 (네트워크/설정 확인)');
      return;
    }
    setState(() => _uploadingAvatar = true);
    try {
      final url = await repo.uploadAvatar(await x.readAsBytes());
      await ref.read(myAvatarProvider.notifier).set(url);
    } catch (_) {
      _snack('사진 업로드에 실패했어요');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: AppText.body(size: 13, color: Colors.white)),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    // 내 프로필이면 최신 프로필 사진을 반영.
    final n = widget.neighbor.isMe
        ? widget.neighbor.copyWith(avatarUrl: ref.watch(myAvatarProvider))
        : widget.neighbor;
    // 이 사람이 실제로 올린 게시물만(샘플 없음).
    final posts = postsByOwner(ref, n.owner);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 흰 헤더: < 뒤로 + 아바타 + 이름/견종 + 이웃 추가
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: topPad + 14,
              left: _hPad(context),
              right: _hPad(context),
              bottom: 14,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/community'),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: _ink, size: 20),
                ),
                const SizedBox(width: 12),
                _HeaderAvatar(
                  neighbor: n,
                  editable: n.isMe,
                  uploading: _uploadingAvatar,
                  onEdit: _pickAvatar,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.owner,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 14.79,
                          weight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${n.petName} · ${n.breed}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(size: 12.68, color: _sub),
                      ),
                    ],
                  ),
                ),
                if (!n.isMe) ...[
                  const SizedBox(width: 8),
                  _FollowButton(
                    following: _following,
                    onTap: () => setState(() => _following = !_following),
                  ),
                ],
              ],
            ),
          ),
          // 통계 바
          _StatsBar(neighbor: n),
          // 사진 그리드
          Expanded(
            child: posts.isEmpty
                ? Center(
                    child: Text(
                      '아직 게시물이 없어요',
                      style: AppText.body(size: 14, color: _sub),
                    ),
                  )
                : GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    padding: EdgeInsets.zero,
                    children: [
                      for (final p in posts) _GridPhoto(post: p),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// 헤더 아바타. 내 프로필이면 우하단 카메라 뱃지를 눌러 사진을 바꾼다.
class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.neighbor,
    required this.editable,
    required this.uploading,
    required this.onEdit,
  });
  final Neighbor neighbor;
  final bool editable;
  final bool uploading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final avatar = PetAvatar(neighbor: neighbor, size: 40, radius: 12);
    if (!editable) return avatar;
    return GestureDetector(
      onTap: uploading ? null : onEdit,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (uploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF4845F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.camera_alt, size: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// 코랄 알약형 "이웃 추가" 버튼(person-add 아이콘 + 텍스트).
class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});
  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: following ? _sub : const Color(0xFFF4845F),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (following)
              const Icon(Icons.check, size: 14, color: Colors.white)
            else
              Image.asset(
                'assets/icons/ic_neighbor_add.png',
                width: 14,
                height: 14,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_add_alt_1, size: 14, color: Colors.white),
              ),
            const SizedBox(width: 5),
            Text(
              following ? '이웃' : '이웃 추가',
              style: AppText.body(
                size: 12.68,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 게시물/이웃/총 좋아요 통계 바. 상·하 테두리 + 세로 구분선(1.06px #F0E8DE).
class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.neighbor});
  final Neighbor neighbor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _line, width: 1.06),
          bottom: BorderSide(color: _line, width: 1.06),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _stat(neighbor.posts, '게시물'),
            _divider(),
            _stat(neighbor.neighbors, '이웃'),
            _divider(),
            _stat(neighbor.totalLikes, '총 좋아요'),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      const VerticalDivider(width: 1.06, thickness: 1.06, color: _line);

  Widget _stat(int count, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppText.body(size: 16.9, weight: FontWeight.w800, color: _ink),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppText.body(size: 12.68, color: _sub)),
          ],
        ),
      ),
    );
  }
}

/// 사진 그리드 한 칸(정사각 + 좌하단 좋아요 수). 탭 → 상세.
class _GridPhoto extends StatelessWidget {
  const _GridPhoto({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/community/post', extra: post),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CommunityPhoto.of(post, radius: 0, aspectRatio: 1, emojiSize: 40),
          Positioned(
            left: 8,
            bottom: 8,
            child: Row(
              children: [
                const Icon(Icons.favorite, size: 14, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  '${post.likes}',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
