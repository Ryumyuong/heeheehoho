import 'package:flutter/material.dart';

import '../domain/community_models.dart';

/// 커뮤니티 화면에 쓰는 예시 데이터.
///
/// 아직 소셜 백엔드가 없어서 전부 하드코딩한 샘플이다.
/// 나중에 서버를 붙이면 이 파일만 Provider/Repository로 갈아끼우면 된다.
class CommunitySample {
  CommunitySample._();

  // ── 이웃(사용자) ──────────────────────────────────────────────
  static const me = Neighbor(
    id: 'me',
    owner: '뭉치맘',
    petName: '뭉치',
    breed: '포메라니안',
    emoji: '🐶',
    avatarColor: Color(0xFFFFE0B2),
    location: '부산 해운대구',
    status: PetStatus.walking,
    posts: 12,
    neighbors: 88,
    totalLikes: 540,
    isMe: true,
  );

  static const coco = Neighbor(
    id: 'coco',
    owner: '코코파파',
    petName: '코코',
    breed: '리트리버',
    emoji: '🦮',
    avatarColor: Color(0xFFFFD59E),
    location: '부산 해운대구',
    status: PetStatus.walking,
    posts: 6,
    neighbors: 134,
    totalLikes: 331,
  );

  static const dubu = Neighbor(
    id: 'dubu',
    owner: '두부맘',
    petName: '두부',
    breed: '비숑',
    emoji: '🐩',
    avatarColor: Color(0xFFEAEAEA),
    location: '부산 수영구',
    status: PetStatus.resting,
    posts: 9,
    neighbors: 76,
    totalLikes: 210,
  );

  static const cookie = Neighbor(
    id: 'cookie',
    owner: '쿠키아빠',
    petName: '쿠키',
    breed: '웰시코기',
    emoji: '🐕',
    avatarColor: Color(0xFFFFCC80),
    location: '부산 남구',
    status: PetStatus.bathing,
    posts: 4,
    neighbors: 51,
    totalLikes: 128,
  );

  static const mocha = Neighbor(
    id: 'mocha',
    owner: '모카언니',
    petName: '모카',
    breed: '푸들',
    emoji: '🐕‍🦺',
    avatarColor: Color(0xFFD7CCC8),
    location: '부산 해운대구',
    status: PetStatus.playing,
    posts: 15,
    neighbors: 203,
    totalLikes: 892,
  );

  static const bori = Neighbor(
    id: 'bori',
    owner: '보리주인',
    petName: '보리',
    breed: '진돗개',
    emoji: '🐺',
    avatarColor: Color(0xFFFFE0B2),
    location: '부산 기장군',
    status: PetStatus.resting,
    posts: 7,
    neighbors: 64,
    totalLikes: 175,
  );

  static const latte = Neighbor(
    id: 'latte',
    owner: '라떼집사',
    petName: '라떼',
    breed: '말티즈',
    emoji: '🐾',
    avatarColor: Color(0xFFF8BBD0),
    location: '부산 동래구',
    status: PetStatus.playing,
    posts: 11,
    neighbors: 97,
    totalLikes: 402,
  );

  /// 이웃 목록 탭 순서(나 제외).
  static const neighbors = <Neighbor>[
    coco,
    dubu,
    cookie,
    mocha,
    bori,
    latte,
  ];

  // ── 밸런스 게임 ──────────────────────────────────────────────
  static const balanceGame = BalanceGame(
    id: 'anxiety_vs_homecam',
    title: '댕댕 밸런스 게임',
    question: '둘 중 하나라면 어느 쪽이 더 공감돼요?',
    optionA: '분리불안 강아지',
    optionB: '홈캠 중독 주인',
    emojiA: '🐶',
    emojiB: '🧑',
    percentA: 44,
    voters: 4217,
  );

  // ── 게시글 ──────────────────────────────────────────────────
  static final List<Post> posts = [
    Post(
      id: 'p1',
      author: coco,
      timeAgo: '3분 전',
      place: '광안리',
      text: '광안리 야경 보면서 산책! 코코가 너무 신나했어요 🌊',
      imageAsset: 'assets/images/community/gwangan_1.webp',
      gradient: const [Color(0xFFFFB56B), Color(0xFFFC7A6E)],
      photoEmoji: '🌅',
      hashtags: ['광안리', '야경산책'],
      likes: 67,
      shares: 12,
      comments: [
        Comment(author: coco, timeAgo: '1시간 전', text: '와 너무 귀여워요! 우리도 가봐야겠어요 🐕'),
        Comment(author: dubu, timeAgo: '30분 전', text: '해운대 산책코스 좋죠! 추천해요 👍'),
        Comment(author: mocha, timeAgo: '15분 전', text: '너무 행복해보여요 ㅎㅎ'),
      ],
    ),
    Post(
      id: 'p2',
      author: mocha,
      timeAgo: '27분 전',
      text: '모카 미용했어요 ✂️ 뽀글이에서 인형이 됐네요 ㅎㅎ',
      gradient: const [Color(0xFFB39DDB), Color(0xFF9575CD)],
      photoEmoji: '✂️',
      hashtags: ['강아지미용', '푸들', '인형됐다'],
      likes: 96,
      shares: 5,
      comments: [
        Comment(author: coco, timeAgo: '20분 전', text: '헐 완전 딴 강아지 됐어요!'),
        Comment(author: cookie, timeAgo: '15분 전', text: '미용 어디서 했어요? 정보 좀요 🙏'),
      ],
    ),
    Post(
      id: 'p3',
      author: cookie,
      timeAgo: '1시간 전',
      text: '쿠키 목욕 대참사 🛁 물만 틀면 도망가는 우리 코기...',
      imageAsset: 'assets/images/community/bath.webp',
      gradient: const [Color(0xFF80DEEA), Color(0xFF4DD0E1)],
      photoEmoji: '🛁',
      hashtags: ['웰시코기', '목욕전쟁', '물싫어'],
      likes: 74,
      shares: 3,
      comments: [
        Comment(author: bori, timeAgo: '40분 전', text: '우리집도 똑같아요 ㅋㅋㅋㅋ'),
      ],
    ),
    Post(
      id: 'p4',
      author: latte,
      timeAgo: '3시간 전',
      text: '라떼 간식 만들기 성공 🍪 수제 고구마 트릿 완전 좋아하네요!',
      gradient: const [Color(0xFFFFD180), Color(0xFFFFAB40)],
      photoEmoji: '🍪',
      hashtags: ['수제간식', '고구마트릿', '말티즈'],
      likes: 152,
      shares: 21,
      comments: [
        Comment(author: dubu, timeAgo: '2시간 전', text: '레시피 공유해주세요!! 🥺'),
        Comment(author: mocha, timeAgo: '1시간 전', text: '금손이시네요 👏'),
      ],
    ),
  ];

  /// 코코파파 프로필(게시물 6)에 쓰는 실제 사진 6장.
  static final List<Post> cocoGallery = [
    _photoPost(coco, 0, 'gwangan_1.png', '🌅', 128),
    _photoPost(coco, 1, 'gwangan_2.png', '🌉', 96),
    _photoPost(coco, 2, 'beach_1.png', '🏖️', 67),
    _photoPost(coco, 3, 'beach_2.png', '🐶', 67),
    _photoPost(coco, 4, 'bath.png', '🛁', 67),
    _photoPost(coco, 5, 'forest.png', '🌳', 67),
  ];

  static Post _photoPost(
    Neighbor n,
    int i,
    String file,
    String emoji,
    int likes,
  ) => Post(
    id: '${n.id}_g$i',
    author: n,
    timeAgo: '${i + 1}일 전',
    text: '${n.petName}의 일상 한 컷',
    imageAsset: 'assets/images/community/$file',
    photoEmoji: emoji,
    likes: likes,
  );

  /// 프로필 화면 사진 그리드에 쓰는 게시물 썸네일.
  static List<Post> postsBy(Neighbor n) {
    // 코코는 실제 사진 6장, 나머지는 그라디언트 썸네일로 채운다.
    if (n.id == coco.id) return cocoGallery;
    final own = posts.where((p) => p.author.id == n.id).toList();
    if (own.isNotEmpty) return own;
    const palettes = [
      [Color(0xFFFFB56B), Color(0xFFFC7A6E)],
      [Color(0xFFB39DDB), Color(0xFF9575CD)],
      [Color(0xFF80DEEA), Color(0xFF4DD0E1)],
      [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
      [Color(0xFFFFD180), Color(0xFFFFAB40)],
      [Color(0xFFF48FB1), Color(0xFFF06292)],
    ];
    const emojis = ['🐾', '🦴', '🎾', '🌳', '☀️', '💛'];
    return List.generate(
      n.posts.clamp(0, 6),
      (i) => Post(
        id: '${n.id}_$i',
        author: n,
        timeAgo: '${i + 1}일 전',
        text: '${n.petName}의 일상 한 컷',
        gradient: palettes[i % palettes.length],
        photoEmoji: emojis[i % emojis.length],
        likes: 40 + i * 17,
      ),
    );
  }
}
