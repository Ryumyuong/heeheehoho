import 'package:flutter/foundation.dart' show kReleaseMode;

import 'data/location_service.dart';

/// 산책 기능 개발용 스위치 모음.
///
/// **릴리즈 빌드에서는 자동으로 꺼진다**([kReleaseMode]로 게이트). 그래서 실수로
/// 시뮬레이션이나 고정 위치가 배포될 일이 없고, 개발(디버그) 중에는 그대로 켜져
/// 편하게 확인할 수 있다. 값을 바꾸고 싶으면 아래 `debug*` 상수만 손대면 된다.

/// (디버그 전용) 고정 위치. 릴리즈에서는 null이 되어 실제 GPS를 쓴다.
const UserPlace? _debugFixedPlace = UserPlace(
  lat: 35.1631, // 부산 해운대구청
  lon: 129.1635,
  name: '부산 해운대구',
);

/// (디버그 전용) GPS 대신 시뮬레이션으로 거리를 채울지. 릴리즈에서는 false.
///
/// 크롬·에뮬레이터에서는 위치가 잡혀도 제자리라 거리가 안 늘어난다. 켜두면
/// 처음부터 시뮬레이션으로 돌려, **화면을 탭해 걷기 → 뛰기 → 더 빨리**로 바꿔가며
/// 확인할 수 있다.
const bool _debugSimulateWalk = true;

/// 고정 위치. null이면 실제 GPS·지오코딩을 쓴다.
const UserPlace? kFixedPlace = kReleaseMode ? null : _debugFixedPlace;

/// true면 GPS 대신 시뮬레이션으로 거리를 채운다.
const bool kSimulateWalk = kReleaseMode ? false : _debugSimulateWalk;
