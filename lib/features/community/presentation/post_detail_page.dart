import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';
import '../domain/community_models.dart';
import 'widgets/community_bits.dart';

double _hPad(BuildContext context) => DesignScale.scaled(context, 20);

/// 게시물 상세: 작성자 + 사진 + 본문 + 댓글 목록 + 댓글 입력.
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post});
  final Post post;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _input = TextEditingController();
  // 화면 안에서만 늘어나는 로컬 댓글(서버 없음).
  late final List<Comment> _comments = [...widget.post.comments];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add(Comment(author: _meAsAuthor, timeAgo: '방금', text: text));
      _input.clear();
    });
    FocusScope.of(context).unfocus();
  }

  // 댓글 작성자를 게시글 작성자와 같은 톤의 아바타로 임시 표현.
  Neighbor get _meAsAuthor => const Neighbor(
    id: 'me',
    owner: '뭉치맘',
    petName: '뭉치',
    breed: '포메라니안',
    emoji: '🐶',
    avatarColor: Color(0xFFFFE0B2),
    location: '부산 해운대구',
  );

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 흰 헤더 + 뒤로가기(<) + "게시물".
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: topPad + 14,
              left: _hPad(context),
              right: _hPad(context),
              bottom: 10,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/community'),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Color(0xFF2D2D2D), size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  '게시물',
                  style: AppText.body(
                    size: 18,
                    color: const Color(0xFF2D2D2D),
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 본문 영역(흰 배경, 좌우 여백).
                Padding(
                  padding: EdgeInsets.fromLTRB(_hPad(context), 8, _hPad(context), 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AuthorRow(author: post.author, timeAgo: post.timeAgo),
                      const SizedBox(height: 14),
                      CommunityPhoto.of(post,
                          radius: 5, aspectRatio: 1.3, emojiSize: 80),
                      const SizedBox(height: 16),
                      Text(
                        post.text,
                        style: AppText.body(
                          size: 16,
                          color: const Color(0xFF2D2D2D),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      HashtagWrap(tags: post.hashtags),
                      if (post.hashtags.isNotEmpty) const SizedBox(height: 16),
                      // 좋아요/댓글/공유 위 가로 구분선.
                      const Divider(
                          color: Color(0x33C0905A), height: 1, thickness: 1),
                      const SizedBox(height: 14),
                      PostStatsRow(
                        likes: post.likes,
                        comments: _comments.length,
                        shares: post.shares,
                        onShare: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('공유 기능은 곧 준비돼요',
                                    style: AppText.body(
                                        size: 13, color: Colors.white)),
                                backgroundColor: AppColors.ink,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                        },
                      ),
                    ],
                  ),
                ),
                // 댓글 영역(배경 #FBF9F9, 풀폭).
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFBF9F9),
                  padding: EdgeInsets.fromLTRB(_hPad(context), 20, _hPad(context), 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '댓글 ${_comments.length}',
                        style: AppText.body(
                          size: 18,
                          weight: FontWeight.w800,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (int i = 0; i < _comments.length; i++) ...[
                        _CommentRow(comment: _comments[i]),
                        if (i != _comments.length - 1) const SizedBox(height: 18),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          _CommentInput(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

/// 작성자 행(아바타 + 이름·정보 + "프로필 보기 →"). 테두리 없이 흰 배경.
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.author, required this.timeAgo});
  final Neighbor author;
  final String timeAgo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PetAvatar(neighbor: author, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.owner,
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w800,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${author.breed} · ${author.location} · $timeAgo',
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: const Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push('/community/profile', extra: author),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '프로필 보기',
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: const Color(0xFFBBBBBB),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward, size: 13, color: Color(0xFFBBBBBB)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});
  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PetAvatar(neighbor: comment.author, size: 40, radius: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.author.owner,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w800,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.timeAgo,
                    style: AppText.body(size: 12, color: const Color(0xFF888888)),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                comment.text,
                style: AppText.body(
                  size: 14,
                  color: const Color(0xFF2D2D2D),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(_hPad(context), 8, _hPad(context), 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: AppText.body(size: 14, color: const Color(0xFF2D2D2D)),
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  hintStyle: AppText.body(
                    size: 14,
                    color: const Color(0xFF2D2D2D).withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F6F2),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSend,
              behavior: HitTestBehavior.opaque,
              child: Image.asset(
                'assets/icons/ic_send.png',
                width: 48,
                height: 48,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4845F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
