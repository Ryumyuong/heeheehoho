import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:upgrader/upgrader.dart';

import 'core/router/app_router.dart';
import 'core/theme/pixel_theme.dart';
import 'features/onboarding/data/nickname_service.dart';
import 'features/pet/application/pet_providers.dart';
import 'features/pet/data/pet_repository.dart';
import 'features/walk/application/walk_providers.dart';
import 'features/walk/data/walk_repository.dart';
import 'shared/widgets/design_scale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 세로 전용 앱 — 가로로 회전해도 세로로 고정한다.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Firebase(닉네임 중복 검사용). 설정이 없거나 실패하면 null로 두고 검사를
  // 건너뛴다(온보딩이 막히지 않게). 설정 파일이 들어오면 자동으로 켜진다.
  FirebaseFirestore? firestore;
  try {
    await Firebase.initializeApp();
    firestore = FirebaseFirestore.instance;
  } catch (_) {
    firestore = null;
  }

  await Hive.initFlutter();
  final petRepo = await PetRepository.open();
  final walkRepo = await WalkRepository.open();

  runApp(
    ProviderScope(
      overrides: [
        petRepositoryProvider.overrideWithValue(petRepo),
        walkRepositoryProvider.overrideWithValue(walkRepo),
        firestoreProvider.overrideWithValue(firestore),
      ],
      child: const HeeheehohoApp(),
    ),
  );
}

/// 마우스·트랙패드·터치·스타일러스 모두 드래그 스크롤 허용(웹/데스크톱 대응).
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class HeeheehohoApp extends StatelessWidget {
  const HeeheehohoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'heeheehoho',
      debugShowCheckedModeBanner: false,
      theme: PixelTheme.light,
      // 웹(마우스)·데스크톱에서도 드래그로 스크롤되도록 허용.
      scrollBehavior: _AppScrollBehavior(),
      routerConfig: appRouter,
      // 시안 폭(412px) 캔버스를 화면 폭에 맞춰 통째로 스케일한다.
      // 폰트·아이콘·이미지·여백이 같은 비율로 함께 커지고 작아진다.
      // UpgradeAlert: 스토어 최신 버전을 확인해 구버전이면 업데이트 안내창을
      // 띄우고 "지금 업데이트" 시 스토어로 보낸다(웹에서는 비활성).
      builder: (context, child) => DesignScale(
        child: kIsWeb
            ? child!
            : UpgradeAlert(
                upgrader: Upgrader(
                  durationUntilAlertAgain: const Duration(hours: 12),
                ),
                showIgnore: false, // "무시" 없이 업데이트 or 나중에
                child: child!,
              ),
      ),
    );
  }
}
