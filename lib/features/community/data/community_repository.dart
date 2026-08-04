import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../onboarding/data/nickname_service.dart' show firestoreProvider;
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

/// "나" 이웃 정보(샘플 기본값 + 실제 프로필 사진 + 실제 펫 이름).
final meProvider = Provider<Neighbor>((ref) {
  final url = ref.watch(myAvatarProvider);
  return CommunitySample.me.copyWith(avatarUrl: url);
});
