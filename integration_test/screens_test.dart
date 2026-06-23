import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pixel_pet/main.dart' as app;

/// 온보딩~홈 플로우를 실제로 구동하며 각 화면을 캡처한다.
/// 실행:
///   flutter drive --driver test_driver/integration_test.dart \
///     --target integration_test/screens_test.dart -d <emulator-id>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 무한 애니메이션(강아지 idle 등)이 있어 pumpAndSettle 대신 고정 프레임 진행.
  Future<void> settle(WidgetTester t, [int ms = 700]) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(Duration(milliseconds: ms ~/ 6));
    }
  }

  Future<void> tapText(WidgetTester t, String text) async {
    await t.tap(find.text(text).last);
    await settle(t);
  }

  testWidgets('온보딩~홈 화면 캡처', (tester) async {
    await app.main();
    await settle(tester, 1200);
    await settle(tester, 1200); // 스플래시 → 로그인

    await binding.convertFlutterSurfaceToImage();
    await settle(tester);

    // 로그인
    await binding.takeScreenshot('01_login');
    await tapText(tester, '비회원으로 시작하기');

    // 펫 유무
    await binding.takeScreenshot('02_has_pet');
    await tapText(tester, '네, 귀여운 네발 친구가 있어요');

    // 사진
    await binding.takeScreenshot('03_photo');
    await tapText(tester, '사진 촬영하기');

    // 스캔완료
    await binding.takeScreenshot('04_scan');
    await tapText(tester, '조금 더 다듬기');

    // 커스터마이즈
    await settle(tester);
    await binding.takeScreenshot('05_customize');
    await tapText(tester, '다음으로');

    // 정보입력
    await binding.takeScreenshot('06_info_empty');
    await tester.enterText(find.byType(TextField).first, '세미');
    await settle(tester);
    await tapText(tester, '공주님');
    await tester.tap(find.byType(Checkbox));
    await settle(tester);
    await binding.takeScreenshot('07_info_filled');
    await tapText(tester, '완성하기');

    // 가입
    await settle(tester);
    await binding.takeScreenshot('08_signup');
    await tapText(tester, '구글로 시작하기');

    // 홈
    await settle(tester, 1000);
    await binding.takeScreenshot('09_home');

    // 홈 - 아이템 패널
    await tapText(tester, 'ITEM');
    await settle(tester, 1000);
    await binding.takeScreenshot('10_home_items');
  });
}
