import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 앱 밖으로 나가는 링크 모음.
class AppLinks {
  AppLinks._();

  /// 개인정보처리방침. 위치·활동 데이터를 수집하므로 두 스토어 모두 필수다.
  static const String privacyPolicy =
      'https://blog.naver.com/fbaudwh/224346025714';
}

/// 외부 브라우저로 [url]을 연다. 실패하면 스낵바로 알린다(조용히 아무 일도
/// 일어나지 않으면 사용자는 버튼이 고장 난 줄 안다).
Future<void> openExternal(BuildContext context, String url) async {
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);

  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('링크를 열지 못했어요.')),
    );
  }
}
