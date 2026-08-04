import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/splash_page.dart';
import '../../features/onboarding/presentation/login_page.dart';
import '../../features/onboarding/presentation/has_pet_page.dart';
import '../../features/onboarding/presentation/photo_page.dart';
import '../../features/onboarding/presentation/scan_page.dart';
import '../../features/onboarding/presentation/customize_page.dart';
import '../../features/onboarding/presentation/info_page.dart';
import '../../features/onboarding/presentation/signup_page.dart';
import '../../features/community/domain/community_models.dart';
import '../../features/community/presentation/community_page.dart';
import '../../features/community/presentation/compose_page.dart';
import '../../features/community/presentation/post_detail_page.dart';
import '../../features/community/presentation/neighbor_profile_page.dart';
import '../../features/games/presentation/games_hub_page.dart';
import '../../features/games/presentation/timer_game_page.dart';
import '../../features/games/presentation/face_game_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/store/presentation/store_page.dart';
import '../../features/store/presentation/charge_page.dart';
import '../../features/walk/presentation/walk_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashPage()),
    GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
    GoRoute(path: '/has-pet', builder: (c, s) => const HasPetPage()),
    GoRoute(path: '/photo', builder: (c, s) => const PhotoPage()),
    GoRoute(path: '/scan', builder: (c, s) => const ScanPage()),
    GoRoute(path: '/customize', builder: (c, s) => const CustomizePage()),
    GoRoute(path: '/info', builder: (c, s) => const InfoPage()),
    GoRoute(path: '/signup', builder: (c, s) => const SignupPage()),
    // 발자국 충전(인앱결제). 셸 밖에 둬서 헤더 뒤로가기로 돌아온다.
    GoRoute(path: '/charge', builder: (c, s) => const ChargePage()),
    // 커뮤니티 상세/프로필. 셸 밖에 둬서 push→뒤로가기로 목록으로 돌아온다.
    // 데이터는 extra로 넘긴다(잘못 진입하면 커뮤니티 홈으로).
    GoRoute(
      path: '/community/post',
      builder: (c, s) {
        final post = s.extra;
        if (post is! Post) return const CommunityPage();
        return PostDetailPage(post: post);
      },
    ),
    GoRoute(
      path: '/community/profile',
      builder: (c, s) {
        final n = s.extra;
        if (n is! Neighbor) return const CommunityPage();
        return NeighborProfilePage(neighbor: n);
      },
    ),
    GoRoute(path: '/community/compose', builder: (c, s) => const ComposePage()),
    // 미니게임
    GoRoute(path: '/games', builder: (c, s) => const GamesHubPage()),
    GoRoute(path: '/games/timer', builder: (c, s) => const TimerGamePage()),
    // 강아지 얼굴 맞추기(게임2)
    GoRoute(path: '/games/face', builder: (c, s) => const FaceGamePage()),

    // 하단 탭 셸: 산책 / 커뮤니티 / 홈(중앙) / 스토어 / 프로필
    // (커뮤니티만 아직 placeholder)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navShell) => MainShell(navShell: navShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/walk', builder: (c, s) => const WalkPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/community', builder: (c, s) => const CommunityPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomePage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/store', builder: (c, s) => const StorePage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (c, s) => const ProfilePage()),
        ]),
      ],
    ),
  ],
);
