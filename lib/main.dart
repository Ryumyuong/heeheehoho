import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

/// 스토어 스크린샷 캡처용 앱 폭(px). 0이면 평소 동작.
/// 예) `flutter run -d web-server --dart-define=SHOT_WIDTH=665`
const int _kShotWidth = int.fromEnvironment('SHOT_WIDTH');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 세로 전용 앱 — 가로로 회전해도 세로로 고정한다.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Firebase. 모바일은 google-services.json / GoogleService-Info.plist 로 자동
  // 초기화되지만, 웹은 설정 파일이 없어서 옵션을 직접 넣어야 한다.
  // 실패하면 null로 두고 관련 기능(중복검사·투표·게시물)을 건너뛴다.
  FirebaseFirestore? firestore;
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCSgGmnSrwLDpJ1Oo3V57Yl6lmh-4ivED0',
          authDomain: 'heeheehoho.firebaseapp.com',
          projectId: 'heeheehoho',
          storageBucket: 'heeheehoho.firebasestorage.app',
          messagingSenderId: '993867911735',
          appId: '1:993867911735:web:f7488318f87ba01d6b65b2',
          measurementId: 'G-RVDFFDTE9N',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    firestore = FirebaseFirestore.instance;
    // 익명 로그인. 화면에 로그인 UI는 없고, 기기마다 uid 하나가 생긴다.
    // 이 uid 로 "내가 쓴 글·댓글"과 "내 이웃"을 서버가 직접 검증한다.
    // 실패해도 앱은 그대로 쓰되, 쓰기 기능만 막힌다.
    //
    // 인터넷이 없으면 응답이 오지 않아 여기서 멈춘다(오프라인 시연 등).
    // 몇 초 기다렸다 포기하고 앱은 그대로 띄운다 — 게임·미니룸은 서버가 없어도
    // 전부 동작하므로 로그인 때문에 첫 화면이 안 나오면 안 된다.
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 5));
    }
  } catch (_) {
    firestore = null;
  }

  await Hive.initFlutter();
  final petRepo = await PetRepository.open();
  final walkRepo = await WalkRepository.open();
  // 커뮤니티 로컬 저장(내 프로필 사진 URL, 밸런스 투표 선택 등).
  await Hive.openBox('community_box');

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
      builder: (context, child) {
        final content = kIsWeb
            ? child!
            : UpgradeAlert(
                upgrader: Upgrader(
                  durationUntilAlertAgain: const Duration(hours: 12),
                ),
                showIgnore: false, // "무시" 없이 업데이트 or 나중에
                child: child!,
              );
        // 미니게임은 큰 화면에서도 꽉 차게(990 제한 해제). 나머지는 990 컬럼 유지.
        final path = appRouter.routerDelegate.currentConfiguration.uri.path;
        final fullWidth = path.startsWith('/games');
        return DesignScale(
          // 스토어 스크린샷용: 웹에서 `--dart-define=SHOT_WIDTH=665` 처럼 주면
          // 앱을 그 폭의 컬럼으로 그린다(기기 비율로 캡처하려고). 기본값 0이면
          // 평소 동작 그대로라 릴리즈 빌드에는 영향이 없다.
          mobileMaxWidth: _kShotWidth > 0
              ? _kShotWidth.toDouble()
              : (fullWidth ? double.infinity : 990),
          child: content,
        );
      },
    );
  }
}
