import 'package:flutter/material.dart';

import '../domain/community_models.dart';

/// 커뮤니티 화면의 고정값.
///
/// 예전에는 이웃·게시물까지 전부 하드코딩한 샘플이었지만, 실제 데이터가
/// 붙으면서 다 걷어냈다. 지금 남은 건 두 가지뿐이다.
/// - [me]: 내 카드의 기본 뼈대(닉네임·펫 이름은 실제 값으로 덮어쓴다)
/// - [balanceGame]: 문항은 고정이고 투표 수는 Firestore 실시간 집계다
class CommunitySample {
  CommunitySample._();

  /// 내 카드의 기본 뼈대. 닉네임·펫 이름은 [meProvider]가 실제 값으로 덮어쓰고,
  /// 게시물·이웃·좋아요 수는 아직 집계 기능이 없어 0으로 둔다(가짜 숫자 금지).
  static const me = Neighbor(
    id: 'me',
    owner: '나',
    petName: '',
    breed: '',
    emoji: '🐶',
    avatarColor: Color(0xFFFFE0B2),
    location: '',
    isMe: true,
  );

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
}
