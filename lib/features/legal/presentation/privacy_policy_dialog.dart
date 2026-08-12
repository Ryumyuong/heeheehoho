import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/theme/pixel_theme.dart';

/// 개인정보처리방침 본문 에셋. 내용을 고칠 때는 이 파일만 고치면 된다.
/// (스토어 심사에 내는 공개 URL은 `AppLinks.privacyPolicy`에 따로 있다.)
const String kPrivacyPolicyAsset = 'assets/legal/privacy_policy.md';

/// 개인정보처리방침을 앱 안 팝업으로 보여준다.
Future<void> showPrivacyPolicy(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _PrivacyPolicyDialog(),
  );
}

class _PrivacyPolicyDialog extends StatelessWidget {
  const _PrivacyPolicyDialog();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // 작은 기기에서도 화면을 꽉 채우지 않도록 여백을 남긴다.
    final maxW = media.size.width - 40;
    final maxH = media.size.height * 0.8;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW.clamp(280, 520), maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더: 제목 + 닫기.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '개인정보처리방침',
                      style: AppText.body(
                        family: 'Pretendard',
                        size: 18,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.subtle,
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Flexible(
              child: FutureBuilder<String>(
                future: rootBundle.loadString(kPrivacyPolicyAsset),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _message('방침을 불러오지 못했어요.');
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _renderMarkdown(snap.data!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _message(String text) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(text,
              style: AppText.body(size: 13, color: AppColors.subtle)),
        ),
      );
}

/// 방침 문서에서 쓰는 마크다운만 최소로 그린다.
///
/// 지원: `#`/`##`/`###` 제목, 문단, `-` 목록, `**굵게**`, 표.
/// 표는 좁은 팝업에서 가로로 눕히면 읽기 어려워서, 행마다
/// "헤더: 값" 묶음으로 풀어 세로로 쌓는다.
List<Widget> _renderMarkdown(String source) {
  final widgets = <Widget>[];
  final lines = source.replaceAll('\r\n', '\n').split('\n');

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    // 표: 헤더 행 다음에 |---| 구분 행이 오는 형태만 다룬다.
    if (line.startsWith('|') &&
        i + 1 < lines.length &&
        _isTableDivider(lines[i + 1])) {
      final header = _splitRow(line);
      int j = i + 2;
      final rows = <List<String>>[];
      while (j < lines.length && lines[j].trim().startsWith('|')) {
        rows.add(_splitRow(lines[j].trim()));
        j++;
      }
      widgets.add(_table(header, rows));
      i = j - 1;
      continue;
    }

    if (line.startsWith('### ')) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 2),
        child: Text(
          line.substring(4).trim(),
          style: AppText.body(
              family: 'Pretendard', size: 13, weight: FontWeight.w800),
        ),
      ));
      continue;
    }

    if (line.startsWith('## ')) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 6),
        child: Text(
          line.substring(3).trim(),
          style: AppText.body(
              family: 'Pretendard', size: 15, weight: FontWeight.w800),
        ),
      ));
      continue;
    }

    if (line.startsWith('# ')) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          line.substring(2).trim(),
          style: AppText.body(
              family: 'Pretendard', size: 17, weight: FontWeight.w800),
        ),
      ));
      continue;
    }

    if (line.startsWith('- ')) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('· ', style: AppText.body(size: 13, height: 1.6)),
            Expanded(child: _rich(line.substring(2).trim(), size: 13)),
          ],
        ),
      ));
      continue;
    }

    widgets.add(Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _rich(line, size: 13),
    ));
  }

  return widgets;
}

bool _isTableDivider(String line) {
  final t = line.trim();
  return t.startsWith('|') && t.replaceAll(RegExp(r'[\s|:-]'), '').isEmpty;
}

List<String> _splitRow(String line) {
  var t = line.trim();
  if (t.startsWith('|')) t = t.substring(1);
  if (t.endsWith('|')) t = t.substring(0, t.length - 1);
  return t.split('|').map((e) => e.trim()).toList();
}

Widget _table(List<String> header, List<List<String>> rows) {
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F4),
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int c = 0; c < row.length; c++)
                  Padding(
                    padding: EdgeInsets.only(top: c == 0 ? 0 : 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 78,
                          child: Text(
                            c < header.length ? header[c] : '',
                            style: AppText.body(
                              size: 11,
                              color: AppColors.subtle,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(child: _rich(row[c], size: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// `**굵게**`만 처리하는 간단한 인라인 렌더러.
Widget _rich(String text, {double size = 13}) {
  final base = AppText.body(size: size, height: 1.6);
  final spans = <TextSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*');
  int last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(TextSpan(
      text: m.group(1),
      style: AppText.body(size: size, height: 1.6, weight: FontWeight.w800),
    ));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

  return RichText(
    text: TextSpan(style: base, children: spans),
  );
}
