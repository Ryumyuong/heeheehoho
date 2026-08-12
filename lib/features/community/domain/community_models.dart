import 'package:flutter/material.dart';

/// 펫의 현재 상태(이웃 목록의 배지).
enum PetStatus { walking, resting, bathing, playing }

extension PetStatusLabel on PetStatus {
  String get label => switch (this) {
    PetStatus.walking => '산책 중',
    PetStatus.resting => '휴식 중',
    PetStatus.bathing => '목욕 중',
    PetStatus.playing => '놀이 중',
  };

  String get emoji => switch (this) {
    PetStatus.walking => '🐾',
    PetStatus.resting => '💤',
    PetStatus.bathing => '🛁',
    PetStatus.playing => '🎾',
  };

  /// 상태 배지 아이콘(번들 png). 없으면 [emoji]로 폴백.
  String get iconAsset => switch (this) {
    PetStatus.walking => 'assets/icons/ic_status_walk.png',
    PetStatus.resting => 'assets/icons/ic_status_rest.png',
    PetStatus.bathing => 'assets/icons/ic_status_bath.png',
    PetStatus.playing => 'assets/icons/ic_status_play.png',
  };

  Color get color => switch (this) {
    PetStatus.walking => const Color(0xFFF4845F),
    PetStatus.resting => const Color(0xFF7E8BFF),
    PetStatus.bathing => const Color(0xFF5FC0F4),
    PetStatus.playing => const Color(0xFF66C06A),
  };
}

/// 커뮤니티 사용자(이웃).
class Neighbor {
  const Neighbor({
    required this.id,
    required this.owner, // 견주 이름 (예: 코코파파)
    required this.petName, // 반려견 이름 (예: 코코)
    required this.breed, // 견종
    required this.emoji, // 아바타 이모지
    required this.avatarColor,
    required this.location,
    this.avatarUrl, // 실제 프로필 사진(Storage URL). 있으면 이모지 대신 사진.
    this.status = PetStatus.resting,
    this.posts = 0,
    this.neighbors = 0,
    this.totalLikes = 0,
    this.isMe = false,
  });

  final String id;
  final String owner;
  final String petName;
  final String breed;
  final String emoji;
  final Color avatarColor;
  final String location;
  final String? avatarUrl;
  final PetStatus status;
  final int posts;
  final int neighbors;
  final int totalLikes;
  final bool isMe;

  Neighbor copyWith({String? avatarUrl, String? owner, String? petName}) =>
      Neighbor(
    id: id,
    owner: owner ?? this.owner,
    petName: petName ?? this.petName,
    breed: breed,
    emoji: emoji,
    avatarColor: avatarColor,
    location: location,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    status: status,
    posts: posts,
    neighbors: neighbors,
    totalLikes: totalLikes,
    isMe: isMe,
  );
}

/// 게시글.
///
/// 사진은 [imageUrl](Firebase Storage 다운로드 URL)이 최우선이고,
/// 없으면 [imageAsset](번들 이미지), 그것도 없으면 [gradient]+[photoEmoji]
/// 플레이스홀더로 대체된다. 서버를 붙이면 [imageUrl]만 채우면 된다.
class Post {
  const Post({
    required this.id,
    required this.author,
    required this.timeAgo,
    required this.text,
    this.place, // 게시 장소(예: 광안리). 없으면 작성자 지역으로 대체.
    this.imageUrl, // Firebase Storage 다운로드 URL(최우선)
    this.imageAsset, // 번들 이미지 경로(폴백)
    this.gradient = const [Color(0xFFFFB56B), Color(0xFFFC7A6E)],
    this.photoEmoji = '🐾', // 사진이 하나도 없을 때 얹는 이모지
    this.hashtags = const [],
    this.likes = 0,
    this.comments = const [],
    this.shares = 0,
  });

  final String id;
  final Neighbor author;
  final String timeAgo;
  final String text;
  final String? place;
  final String? imageUrl;
  final String? imageAsset;
  final List<Color> gradient;
  final String photoEmoji;
  final List<String> hashtags;
  final int likes;
  final List<Comment> comments;
  final int shares;
}

/// 댓글.
class Comment {
  const Comment({
    this.id = '',
    required this.author,
    required this.timeAgo,
    required this.text,
  });

  /// Firestore 문서 ID. 삭제할 때 쓴다(샘플·임시 댓글은 빈 문자열).
  final String id;
  final Neighbor author;
  final String timeAgo;
  final String text;
}

/// 밸런스 게임(투표).
class BalanceGame {
  const BalanceGame({
    required this.id,
    required this.title,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.emojiA,
    required this.emojiB,
    required this.percentA,
    required this.voters,
  });

  final String id; // Firestore 문서 키
  final String title;
  final String question; // 부제(질문)
  final String optionA;
  final String optionB;
  final String emojiA;
  final String emojiB;
  final int percentA; // A 득표율(%)
  final int voters; // 참여자 수

  int get percentB => 100 - percentA;
}
