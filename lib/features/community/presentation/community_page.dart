import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';
import '../../../shared/widgets/wallet_chip.dart';
import '../../pet/application/pet_providers.dart';
import '../data/balance_vote_service.dart';
import '../data/community_repository.dart';
import '../data/community_sample.dart';
import '../domain/community_models.dart';
import 'widgets/community_bits.dart';

/// 좌우 여백. 다른 페이지(스토어·프로필)와 동일하게 28px.
double _hPad(BuildContext context) => DesignScale.scaled(context, 28);

/// 커뮤니티: 동네 소식(피드) / 이웃 목록 탭.
class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  int _tab = 0; // 0 동네 소식, 1 이웃 목록

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petProvider);
    final paws = pet?.paws ?? 0;
    final bones = pet?.bones ?? 0;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      // 동네 소식 탭에서만 글쓰기 버튼.
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/community/compose'),
              backgroundColor: const Color(0xFFF4845F),
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              label: Text(
                '글쓰기',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          _Header(paws: paws, bones: bones, topPad: topPad),
          _TabToggle(
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tab == 0 ? const _FeedTab() : const _NeighborTab(),
          ),
        ],
      ),
    );
  }
}

// ── 상단 오렌지 헤더 ──
class _Header extends StatelessWidget {
  const _Header({
    required this.paws,
    required this.bones,
    required this.topPad,
  });
  final int paws;
  final int bones;
  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: topPad + 62,
        left: _hPad(context),
        right: _hPad(context),
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '커뮤니티',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                family: 'Pretendard',
                size: 23,
                color: Colors.white,
                weight: FontWeight.w800,
              ),
            ),
          ),
          WalletChip.paws(_comma(paws), onTap: () => context.push('/charge')),
          // 마켓이 닫혀 있는 동안 뼈다귀는 감춘다(kBonesEnabled).
          if (kBonesEnabled) ...[
            const SizedBox(width: 8),
            WalletChip.bones(_comma(bones)),
          ],
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFC6F00),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/icons/cart.png',
              width: 18,
              height: 18,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.shopping_cart, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 동네 소식 / 이웃 목록 탭 토글 ──
class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const Color _selFg = Color(0xFFF4845F);
  static const Color _unselFg = Color(0xFFBBBBBB);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          _seg(0, '동네 소식'),
          _seg(1, '이웃 목록'),
        ],
      ),
    );
  }

  Widget _seg(int i, String label) {
    final selected = index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(i),
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? _selFg : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w700,
              color: selected ? _selFg : _unselFg,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 동네 소식(피드) 탭 ──
class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firestore 실시간 게시물(최신순) + 아래로 샘플 게시물.
    final live = ref.watch(communityPostsProvider).asData?.value ?? const [];
    final posts = [...live, ...CommunitySample.posts];
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 88), // FAB 가림 방지 하단 여백
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _hPad(context)),
          child: _BalanceGameCard(game: CommunitySample.balanceGame),
        ),
        const SizedBox(height: 16),
        for (final post in posts) _PostCard(post: post),
      ],
    );
  }
}

/// 댕댕 밸런스 게임(투표) 카드.
/// 선택한 쪽에 테두리(#FDCBA7)가 생기고, 표 수·게이지·퍼센트는 Firestore로 실시간 집계된다.
class _BalanceGameCard extends ConsumerStatefulWidget {
  const _BalanceGameCard({required this.game});
  final BalanceGame game;

  @override
  ConsumerState<_BalanceGameCard> createState() => _BalanceGameCardState();
}

class _BalanceGameCardState extends ConsumerState<_BalanceGameCard> {
  static const _coral = Color(0xFFF4845F);
  static const _green = Color(0xFF76C442);

  int? _selected; // 0=A, 1=B, null=미투표

  @override
  void initState() {
    super.initState();
    // 이전에 이 기기에서 투표한 선택을 복원(테두리 표시 + 중복 증가 방지).
    final svc = ref.read(balanceVoteServiceProvider);
    svc.loadMyChoice(widget.game.id).then((c) {
      if (mounted && c != null) setState(() => _selected = c);
    });
  }

  int get _seedA =>
      (widget.game.voters * widget.game.percentA / 100).round();
  int get _seedB => widget.game.voters - _seedA;

  Future<void> _onVote(int choice) async {
    final prev = _selected;
    if (prev == choice) return;
    setState(() => _selected = choice); // 즉시 반영(테두리)
    final svc = ref.read(balanceVoteServiceProvider);
    await svc.vote(
      widget.game.id,
      choice: choice,
      previous: prev,
      seedA: _seedA,
      seedB: _seedB,
    );
    await svc.saveMyChoice(widget.game.id, choice);
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.read(balanceVoteServiceProvider).watch(widget.game.id);
    // Firestore가 없으면(초기화 실패) 로컬 계산으로 폴백.
    if (stream == null) {
      return _view(votesA: _seedA + (_selected == 0 ? 1 : 0),
          votesB: _seedB + (_selected == 1 ? 1 : 0));
    }
    return StreamBuilder<({int votesA, int votesB})>(
      stream: stream,
      builder: (context, snap) {
        int va = snap.data?.votesA ?? 0;
        int vb = snap.data?.votesB ?? 0;
        // 아직 아무도 투표 안 해 문서가 없으면(0/0) 시안 기준값을 보여준다.
        if (va == 0 && vb == 0) {
          va = _seedA + (_selected == 0 ? 1 : 0);
          vb = _seedB + (_selected == 1 ? 1 : 0);
        }
        return _view(votesA: va, votesB: vb);
      },
    );
  }

  Widget _view({required int votesA, required int votesB}) {
    final game = widget.game;
    final total = votesA + votesB;
    final pctA = total == 0 ? 0 : (votesA / total * 100).round();
    final pctB = 100 - pctA;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDCBA7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            spreadRadius: -4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목: 불꽃 아이콘 + "댕댕 밸런스 게임"
          Row(
            children: [
              Image.asset(
                'assets/icons/flame.png',
                width: 16,
                height: 16,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) =>
                    const Text('🔥', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 6),
              Text(
                game.title,
                style: AppText.body(size: 12, weight: FontWeight.w800, color: _coral),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${game.optionA} VS ${game.optionB}',
            style: AppText.body(
              size: 14,
              weight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${game.question} · ${_comma(total)}명 참여',
            style: AppText.body(
              size: 12,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          // 선택지 두 개 + 가운데 VS
          Row(
            children: [
              Expanded(
                child: _Option(
                  emoji: game.emojiA,
                  label: game.optionA,
                  selected: _selected == 0,
                  onTap: () => _onVote(0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'VS',
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: _coral.withValues(alpha: 0.36),
                  ),
                ),
              ),
              Expanded(
                child: _Option(
                  emoji: game.emojiB,
                  label: game.optionB,
                  selected: _selected == 1,
                  onTap: () => _onVote(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 득표율
          Row(
            children: [
              Text(
                '$pctA%',
                style: AppText.body(size: 12, weight: FontWeight.w800, color: _coral),
              ),
              const Spacer(),
              Text(
                '$pctB%',
                style: AppText.body(size: 12, weight: FontWeight.w800, color: _green),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _TwoToneGauge(leftFlex: votesA, rightFlex: votesB),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '투표하면 실시간 현황을 볼 수 있어요',
              style: AppText.body(
                size: 12,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 선택지 알약(이모지 + 라벨). 배경 #FEF7F1. 선택 시 테두리 #FDCBA7.
class _Option extends StatelessWidget {
  const _Option({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF7F1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? const Color(0xFFFDCBA7) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w800,
                  color: const Color(0xFF202020),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 좌(코랄)·우(그린) 2색 게이지. radius 999.
class _TwoToneGauge extends StatelessWidget {
  const _TwoToneGauge({required this.leftFlex, required this.rightFlex});
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 12,
        // stretch: 빈 ColoredBox가 세로로 꽉 차게(안 그러면 높이 0으로 접혀 안 보임).
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: leftFlex,
              child: const ColoredBox(color: Color(0xFFF4845F)),
            ),
            Expanded(
              flex: rightFlex,
              child: const ColoredBox(color: Color(0xFF76C442)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 피드의 게시글 카드. 탭하면 상세로, 이름/아바타 탭하면 프로필로.
/// 카드 테두리 대신 아래쪽 구분선(1px #F0E8DE)으로 글을 나눈다.
class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/community/post', extra: post),
      child: Container(
        padding: EdgeInsets.fromLTRB(_hPad(context), 16, _hPad(context), 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF0E8DE))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorRow(
              author: post.author,
              place: post.place ?? post.author.location,
              timeAgo: post.timeAgo,
            ),
            const SizedBox(height: 12),
            Text(
              post.text,
              style: AppText.body(
                size: 14,
                color: const Color(0xFF2D2D2D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            CommunityPhoto.of(post, radius: 5),
            const SizedBox(height: 12),
            HashtagWrap(tags: post.hashtags),
            if (post.hashtags.isNotEmpty) const SizedBox(height: 14),
            PostStatsRow(
              likes: post.likes,
              comments: post.comments.length,
              shares: post.shares,
              onComment: () => context.push('/community/post', extra: post),
              onShare: () => _snack(context, '공유 기능은 곧 준비돼요'),
            ),
          ],
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg, style: AppText.body(size: 13, color: Colors.white)),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

/// 작성자 한 줄(아바타 + 이름·장소·시간). 이름/아바타 탭 → 프로필.
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.author,
    required this.place,
    required this.timeAgo,
  });
  final Neighbor author;
  final String place;
  final String timeAgo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/community/profile', extra: author),
      child: Row(
        children: [
          PetAvatar(neighbor: author, size: 40),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.owner,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$place · $timeAgo',
                style: AppText.body(size: 12, color: const Color(0xFFBBBBBB)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 이웃 목록 탭 ──
class _NeighborTab extends ConsumerWidget {
  const _NeighborTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neighbors = CommunitySample.neighbors;
    return ListView(
      padding: EdgeInsets.fromLTRB(_hPad(context), 8, _hPad(context), 24),
      children: [
        _MyCard(me: ref.watch(meProvider)),
        const SizedBox(height: 12),
        const _NicknameSearchButton(),
        const SizedBox(height: 16),
        // 이웃 목록 흰 박스(둥근 16, 테두리 #F0E8DE) + 헤더 + 행/구분선.
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0E8DE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  '이웃 ${neighbors.length}명',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFF888888),
                  ),
                ),
              ),
              for (int i = 0; i < neighbors.length; i++) ...[
                if (i != 0)
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF5F0EA)),
                _NeighborRow(neighbor: neighbors[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 내 카드 아래 "닉네임으로 이웃찾기" 버튼. 누르면 닉네임 검색 모달.
class _NicknameSearchButton extends StatelessWidget {
  const _NicknameSearchButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (_) => const _NicknameSearchDialog(),
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E2DA),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/ic_search_add.png',
              width: 16,
              height: 16,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: 6),
            Text(
              '닉네임으로 이웃찾기',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w500,
                color: const Color(0xFFA5A095),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 닉네임 검색 모달. 검색 결과 줄은 이웃 목록 줄과 동일한 모양.
class _NicknameSearchDialog extends StatefulWidget {
  const _NicknameSearchDialog();

  @override
  State<_NicknameSearchDialog> createState() => _NicknameSearchDialogState();
}

class _NicknameSearchDialogState extends State<_NicknameSearchDialog> {
  final _ctrl = TextEditingController();
  List<Neighbor>? _results; // null = 아직 검색 전.

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search() {
    final q = _ctrl.text.trim();
    FocusScope.of(context).unfocus();
    if (q.isEmpty) {
      setState(() => _results = null);
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _results = CommunitySample.neighbors
          .where((n) => n.owner.toLowerCase().contains(lower))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: size.height * 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목 + 닫기.
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '닉네임 검색',
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 20,
                      weight: FontWeight.w800,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          'assets/icons/ic_close_x.png',
                          width: 18,
                          height: 18,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // 입력창.
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF5EE),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFF4845F)),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icons/ic_search.png',
                      width: 15,
                      height: 15,
                      filterQuality: FilterQuality.medium,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        style: AppText.body(
                          size: 14,
                          color: const Color(0xFF000000),
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: '닉네임을 입력하세요',
                          hintStyle: AppText.body(
                            size: 14,
                            color: const Color(0xFF000000)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 검색 버튼.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _search,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFD8B3E),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '검색',
                    style: AppText.body(
                      size: 16,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final results = _results;
    if (results == null) return const SizedBox.shrink();
    if (results.isEmpty) {
      return Center(
        child: Text(
          '검색 결과가 없어요',
          style: AppText.body(size: 13, color: const Color(0xFFA5A095)),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final n = results[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0E8DE)),
          ),
          child: _NeighborRow(
            neighbor: n,
            onTap: () {
              Navigator.of(context).pop();
              context.push('/community/profile', extra: n);
            },
          ),
        );
      },
    );
  }
}

/// 내 프로필 카드(흰 배경, 둥근 16, 테두리 #F0E8DE).
class _MyCard extends StatelessWidget {
  const _MyCard({required this.me});
  final Neighbor me;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/community/profile', extra: me),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E8DE)),
        ),
        child: Row(
          children: [
            PetAvatar(neighbor: me, size: 48, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        me.owner,
                        style: AppText.body(
                          size: 16,
                          weight: FontWeight.w800,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4845F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '나',
                          style: AppText.body(
                            size: 12,
                            weight: FontWeight.w700,
                            color: const Color(0xFFF4845F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${me.petName} · ${me.breed}',
                    style: AppText.body(size: 12, color: const Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            StatusPill(status: me.status, background: const Color(0xFFFFF8F0)),
          ],
        ),
      ),
    );
  }
}

/// 이웃 한 줄(흰 박스 안). 탭 → 그 이웃 프로필.
class _NeighborRow extends StatelessWidget {
  const _NeighborRow({required this.neighbor, this.onTap});
  final Neighbor neighbor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => context.push('/community/profile', extra: neighbor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            PetAvatar(neighbor: neighbor, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    neighbor.owner,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w800,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${neighbor.petName} · ${neighbor.breed}',
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(
              status: neighbor.status,
              background: const Color(0xFFF5F5F5),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

String _comma(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
