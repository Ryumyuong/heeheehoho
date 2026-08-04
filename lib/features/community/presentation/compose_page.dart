import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/design_scale.dart';
import '../data/community_repository.dart';

double _hPad(BuildContext context) => DesignScale.scaled(context, 28);

const _ink = Color(0xFF2D2D2D);
const _sub = Color(0xFF888888);

/// 새 게시물 작성: 사진 선택 → Storage 업로드 → Firestore 저장.
class ComposePage extends ConsumerStatefulWidget {
  const ComposePage({super.key});

  @override
  ConsumerState<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends ConsumerState<ComposePage> {
  final _text = TextEditingController();
  final _tags = TextEditingController();
  final _place = TextEditingController();
  Uint8List? _bytes;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    _tags.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    // 업로드 전 압축(대부분 1~2MB). 10MB 상한에 걸릴 일이 없다.
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1440,
    );
    if (x == null) return;
    final b = await x.readAsBytes();
    if (mounted) setState(() => _bytes = b);
  }

  List<String> _parseTags() => _tags.text
      .replaceAll('#', ' ')
      .split(RegExp(r'[\s,]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  bool get _canSubmit => _bytes != null && _text.text.trim().isNotEmpty && !_busy;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final repo = ref.read(communityRepositoryProvider);
    if (!repo.available) {
      _snack('지금은 게시물을 올릴 수 없어요 (네트워크/설정 확인)');
      return;
    }
    setState(() => _busy = true);
    try {
      await repo.createPost(
        author: ref.read(meProvider),
        text: _text.text.trim(),
        place: _place.text.trim().isEmpty ? null : _place.text.trim(),
        imageBytes: _bytes!,
        hashtags: _parseTags(),
      );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('업로드에 실패했어요. 잠시 후 다시 시도해 주세요');
      }
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
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 헤더: < 새 글    [등록]
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: topPad + 14,
              left: _hPad(context),
              right: _hPad(context),
              bottom: 12,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/community'),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.arrow_back_ios_new, color: _ink, size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  '새 글',
                  style: AppText.body(size: 18, weight: FontWeight.w800, color: _ink),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _canSubmit ? _submit : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _canSubmit
                          ? const Color(0xFFF4845F)
                          : const Color(0xFFF0E0D6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            '등록',
                            style: AppText.body(
                              size: 14,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(_hPad(context), 8, _hPad(context), 24),
              children: [
                // 사진 선택 영역
                GestureDetector(
                  onTap: _busy ? null : _pick,
                  behavior: HitTestBehavior.opaque,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1.3,
                      child: _bytes == null
                          ? Container(
                              color: const Color(0xFFF6F1EB),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined,
                                      size: 34, color: _sub),
                                  const SizedBox(height: 8),
                                  Text('사진 추가',
                                      style: AppText.body(
                                          size: 13, color: _sub)),
                                ],
                              ),
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_bytes!, fit: BoxFit.cover),
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: GestureDetector(
                                    onTap: _busy ? null : _pick,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text('변경',
                                          style: AppText.body(
                                              size: 12,
                                              weight: FontWeight.w700,
                                              color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _field(_text, '오늘 네발 친구와 어떤 하루였나요?', maxLines: 5),
                const SizedBox(height: 12),
                _field(_tags, '해시태그 (예: 해운대 산책)', prefix: '#'),
                const SizedBox(height: 12),
                _field(_place, '위치 (예: 광안리)', prefix: '📍'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {int maxLines = 1, String? prefix}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}), // 등록 버튼 활성화 갱신
      style: AppText.body(size: 15, color: _ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(size: 15, color: _sub),
        prefixText: prefix == null ? null : '$prefix ',
        filled: true,
        fillColor: const Color(0xFFF8F6F2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
