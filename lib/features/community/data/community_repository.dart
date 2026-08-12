import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../onboarding/data/nickname_service.dart' show firestoreProvider;
import '../../pet/application/pet_providers.dart';
import '../domain/community_models.dart';
import 'community_sample.dart';

/// 커뮤니티 사진 업로드(Storage) + 게시물 저장/구독(Firestore).
///
/// Firebase 초기화 실패 시(_db == null) [available]이 false가 되고,
/// 업로드/작성은 막히며 피드는 샘플만 보여준다.
class CommunityRepository {
  CommunityRepository(this._db);

  final FirebaseFirestore? _db;

  bool get available => _db != null;
  // _db가 있으면 Firebase가 초기화된 것이므로 Storage도 안전하게 접근된다.
  FirebaseStorage? get _storage => _db == null ? null : FirebaseStorage.instance;

  static const _postsCol = 'community_posts';

  /// 익명 로그인으로 받은 내 uid. 글·댓글에 함께 저장해 두면 보안 규칙이
  /// "본인 것만 삭제"를 서버에서 직접 검증할 수 있다.
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── 사진 업로드 ────────────────────────────────────────────────
  /// [path](예: community/posts/abc.jpg)에 이미지 바이트를 올리고 다운로드 URL을 돌려준다.
  Future<String> uploadImage(String path, Uint8List bytes) async {
    final storage = _storage;
    if (storage == null) throw StateError('Storage를 사용할 수 없어요');
    final ref = storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  // ── 게시물 ────────────────────────────────────────────────────
  /// 새 게시물 작성: 사진을 Storage에 올리고 메타데이터를 Firestore에 저장.
  Future<void> createPost({
    required Neighbor author,
    required String text,
    String? place,
    required Uint8List imageBytes,
    List<String> hashtags = const [],
  }) async {
    final db = _db;
    if (db == null) throw StateError('로그인/네트워크가 필요해요');
    final doc = db.collection(_postsCol).doc();
    final url = await uploadImage('community/posts/${doc.id}.jpg', imageBytes);
    await doc.set({
      'authorUid': _uid,
      'ownerName': author.owner,
      'petName': author.petName,
      'breed': author.breed,
      'emoji': author.emoji,
      'avatarColor': author.avatarColor.toARGB32(),
      'avatarUrl': author.avatarUrl,
      'location': author.location,
      'place': place,
      'text': text,
      'imageUrl': url,
      'hashtags': hashtags,
      'likes': 0,
      'shares': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 내가 쓴 게시물을 지운다. 사진(Storage)까지 같이 지워야 용량이 남지 않는다.
  ///
  /// 사진 삭제가 실패해도(이미 지워졌거나 권한 문제) 게시물은 지운다 —
  /// 피드에서 사라지는 게 먼저다.
  Future<void> deletePost(String postId) async {
    final db = _db;
    if (db == null) throw StateError('네트워크가 필요해요');
    try {
      await _storage?.ref('community/posts/$postId.jpg').delete();
    } catch (_) {
      // 사진이 없거나 지울 수 없어도 계속 진행한다.
    }
    await db.collection(_postsCol).doc(postId).delete();
  }

  // ── 댓글 ──────────────────────────────────────────────────────
  // 게시물 문서 아래 `comments` 하위 컬렉션에 오래된 순으로 쌓는다.

  /// [postId]의 댓글 실시간 스트림(오래된 순). Firestore가 없으면 빈 목록.
  Stream<List<Comment>> watchComments(String postId) {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return db
        .collection(_postsCol)
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(_commentFromDoc).toList());
  }

  Future<void> addComment({
    required String postId,
    required Neighbor author,
    required String text,
  }) async {
    final db = _db;
    if (db == null) throw StateError('네트워크가 필요해요');
    await db.collection(_postsCol).doc(postId).collection('comments').add({
      'authorUid': _uid,
      'ownerName': author.owner,
      'petName': author.petName,
      'emoji': author.emoji,
      'avatarColor': author.avatarColor.toARGB32(),
      'avatarUrl': author.avatarUrl,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final db = _db;
    if (db == null) throw StateError('네트워크가 필요해요');
    await db
        .collection(_postsCol)
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Comment _commentFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final ts = (m['createdAt'] as Timestamp?)?.toDate();
    final owner = (m['ownerName'] as String?) ?? '이웃';
    return Comment(
      id: d.id,
      author: Neighbor(
        id: owner,
        owner: owner,
        petName: (m['petName'] as String?) ?? '',
        breed: '',
        emoji: (m['emoji'] as String?) ?? '🐾',
        avatarColor: Color((m['avatarColor'] as num?)?.toInt() ?? 0xFFFFE0B2),
        location: '',
        avatarUrl: m['avatarUrl'] as String?,
      ),
      timeAgo: _timeAgo(ts),
      text: (m['text'] as String?) ?? '',
    );
  }

  /// 최신순 게시물 실시간 스트림. Firestore가 없으면 빈 목록.
  Stream<List<Post>> watchPosts() {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return db
        .collection(_postsCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_postFromDoc).toList());
  }

  Post _postFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final ts = (m['createdAt'] as Timestamp?)?.toDate();
    final author = Neighbor(
      id: 'post_${d.id}',
      owner: (m['ownerName'] as String?) ?? '익명',
      petName: (m['petName'] as String?) ?? '',
      breed: (m['breed'] as String?) ?? '',
      emoji: (m['emoji'] as String?) ?? '🐶',
      avatarColor: Color((m['avatarColor'] as num?)?.toInt() ?? 0xFFFFE0B2),
      location: (m['location'] as String?) ?? '',
      avatarUrl: m['avatarUrl'] as String?,
    );
    return Post(
      id: d.id,
      author: author,
      timeAgo: _timeAgo(ts),
      place: m['place'] as String?,
      text: (m['text'] as String?) ?? '',
      imageUrl: m['imageUrl'] as String?,
      hashtags: ((m['hashtags'] as List?)?.cast<String>()) ?? const [],
      likes: (m['likes'] as num?)?.toInt() ?? 0,
      shares: (m['shares'] as num?)?.toInt() ?? 0,
    );
  }

  static String _timeAgo(DateTime? t) {
    if (t == null) return '방금';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  // ── 내 프로필 사진 ─────────────────────────────────────────────
  /// 프로필 사진을 Storage에 올리고 다운로드 URL을 돌려준다.
  Future<String> uploadAvatar(Uint8List bytes) {
    // 파일명에 시간 요소가 없어도 매번 같은 경로를 덮어써 최신만 유지한다.
    return uploadImage('community/avatars/me.jpg', bytes);
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(ref.watch(firestoreProvider)),
);

/// 실시간 게시물 목록(Firestore).
final communityPostsProvider = StreamProvider<List<Post>>(
  (ref) => ref.watch(communityRepositoryProvider).watchPosts(),
);

/// 내 프로필 사진 URL(로컬 Hive 영속). 업로드 후 [MyAvatarController.set]으로 갱신.
class MyAvatarController extends Notifier<String?> {
  static const _boxName = 'community_box';
  static const _key = 'my_avatar_url';

  @override
  String? build() {
    if (!Hive.isBoxOpen(_boxName)) return null;
    final v = Hive.box(_boxName).get(_key);
    return v is String && v.isNotEmpty ? v : null;
  }

  Future<void> set(String url) async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    await box.put(_key, url);
    state = url;
  }
}

final myAvatarProvider =
    NotifierProvider<MyAvatarController, String?>(MyAvatarController.new);

/// "나" 이웃 정보(샘플 기본값 + 실제 프로필 사진 + 온보딩에서 정한 닉네임·펫 이름).
///
/// [Neighbor.owner]가 곧 내 닉네임이고, 게시물의 `ownerName`과 맞춰 보아
/// 내가 쓴 글인지 판별한다(닉네임은 중복 예약이 안 되므로 서로 겹치지 않는다).
final meProvider = Provider<Neighbor>((ref) {
  final url = ref.watch(myAvatarProvider);
  final pet = ref.watch(petProvider);
  return CommunitySample.me.copyWith(
    avatarUrl: url,
    owner: (pet?.ownerNickname.isNotEmpty ?? false) ? pet!.ownerNickname : null,
    petName: (pet?.name.isNotEmpty ?? false) ? pet!.name : null,
  );
});

/// 게시물별 댓글 실시간 목록.
final commentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).watchComments(postId);
});

/// 실제 이웃 목록 — 커뮤니티에 글을 올린 사람들(나 제외, 중복 제거).
///
/// 팔로우 같은 관계 데이터가 아직 없어서, 앱에서 실제로 만날 수 있는 "이웃"은
/// 게시물 작성자가 전부다. 샘플 이웃을 섞으면 없는 사람이 있는 것처럼 보인다.
final neighborsProvider = Provider<List<Neighbor>>((ref) {
  final posts = ref.watch(communityPostsProvider).asData?.value ?? const [];
  final me = ref.watch(myNicknameProvider);
  final byOwner = <String, Neighbor>{};
  for (final p in posts) {
    final owner = p.author.owner;
    if (owner.isEmpty || owner == me) continue;
    byOwner.putIfAbsent(owner, () => p.author);
  }
  return byOwner.values.toList();
});

/// [owner] 닉네임이 쓴 실제 게시물들.
List<Post> postsByOwner(WidgetRef ref, String owner) {
  final posts = ref.watch(communityPostsProvider).asData?.value ?? const [];
  return posts.where((p) => p.author.owner == owner).toList();
}

/// 지금 내 닉네임. 아직 정하지 않았으면 null(그때는 삭제 버튼도 안 띄운다).
final myNicknameProvider = Provider<String?>((ref) {
  final n = ref.watch(petProvider)?.ownerNickname ?? '';
  return n.isEmpty ? null : n;
});
