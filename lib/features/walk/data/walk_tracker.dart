import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// 위치 한 건에서 뽑아낸 이동량.
class WalkStep {
  const WalkStep({required this.meters, required this.metersPerSecond});

  /// 직전 지점에서 이만큼 움직였다(m).
  final double meters;

  /// 그 순간의 속도(m/s).
  final double metersPerSecond;
}

/// GPS로 산책 거리를 재는 트래커.
///
/// 화면이 꺼져 있어도 계속 받으려면 백그라운드에서 위치를 받아야 한다.
/// - Android: 포그라운드 서비스 알림을 띄운 채로 받는다(그래야 OS가 안 끊는다).
/// - iOS: `allowBackgroundLocationUpdates` + Info.plist의 UIBackgroundModes.
///
/// GPS는 가만히 있어도 좌표가 흔들려서 그냥 더하면 거리가 부풀어 오른다.
/// 그래서 [_accept]에서 정확도가 나쁜 점, 너무 짧은 이동, 사람이 낼 수 없는
/// 속도의 점프를 걸러낸다.
class WalkTracker {
  StreamSubscription<Position>? _sub;
  Position? _last;

  /// 이 값보다 오차가 큰 위치는 버린다(m). 너무 크면 제자리에서도 좌표가 튄다.
  static const double _maxAccuracy = 35;

  /// 이 거리보다 짧은 이동은 GPS 흔들림으로 본다(m).
  /// 제자리에 서 있을 때 좌표가 흔들려 거리가 늘지 않도록 넉넉히 잡는다.
  static const double _minMove = 6;

  /// 사람이 낼 수 없는 속도(m/s). 이보다 빠른 점프는 튄 좌표로 본다.
  static const double _maxSpeed = 8;

  bool get isTracking => _sub != null;

  /// 위치 권한을 확인·요청한다. 백그라운드까지 받으려면 `always`가 필요하지만,
  /// `whileInUse`만 줘도 앱이 떠 있는 동안은 정상 동작하므로 막지 않는다.
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.whileInUse ||
        p == LocationPermission.always;
  }

  /// 추적 시작. 이동이 감지될 때마다 [onStep]이 불린다.
  /// 시작하지 못하면 false(권한 거부·위치 꺼짐·미지원 플랫폼).
  Future<bool> start(void Function(WalkStep step) onStep) async {
    await stop();
    if (!await ensurePermission()) return false;

    // Android 13+에서 "산책 기록 중" 포그라운드 알림이 보이려면 알림 권한이 필요.
    // (없어도 추적은 되지만 알림이 가려진다) 실패해도 산책은 진행한다.
    if (!kIsWeb) {
      final n = await Permission.notification.status;
      if (!n.isGranted) await Permission.notification.request();
    }

    _last = null;
    try {
      _sub = Geolocator.getPositionStream(locationSettings: _settings()).listen(
        (pos) {
          final step = _accept(pos);
          if (step != null) onStep(step);
        },
        onError: (_) {
          // 신호가 끊겨도 산책 자체는 이어지게 둔다(거리만 안 늘어난다).
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _last = null;
  }

  LocationSettings _settings() {
    // distanceFilter: 이만큼 움직여야 이벤트가 온다. 배터리도 아끼고
    // 제자리 흔들림도 어느 정도 걸러진다. 너무 크면 달리기·정지 반응이 늦어진다.
    const filter = 4;
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: filter,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: filter,
          // 화면이 꺼져도 위치를 계속 받으려면 포그라운드 서비스가 필요하다.
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: '산책 기록 중',
            notificationText: '우리 강아지와 걷는 거리를 재고 있어요',
            notificationIcon: AndroidResource(
              name: 'ic_launcher',
              defType: 'mipmap',
            ),
            enableWakeLock: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: filter,
          activityType: ActivityType.fitness,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
          // iOS가 알아서 위치 갱신을 멈추면 거리가 새므로 끈다.
          pauseLocationUpdatesAutomatically: false,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: filter,
        );
    }
  }

  /// 새 좌표를 받아 이동량을 계산한다. 믿을 수 없는 점이면 null.
  WalkStep? _accept(Position pos) {
    if (pos.accuracy > _maxAccuracy) return null;

    final prev = _last;
    if (prev == null) {
      _last = pos; // 첫 점은 기준만 잡고 거리에 넣지 않는다.
      return null;
    }

    final meters = Geolocator.distanceBetween(
      prev.latitude,
      prev.longitude,
      pos.latitude,
      pos.longitude,
    );
    final dt = pos.timestamp.difference(prev.timestamp).inMilliseconds / 1000;

    if (meters < _minMove) return null; // 제자리 흔들림
    if (dt <= 0) return null;
    if (meters / dt > _maxSpeed) {
      // 튄 좌표. 기준점만 옮기고 거리에는 안 넣는다.
      _last = pos;
      return null;
    }

    _last = pos;
    // GPS가 주는 속도가 있으면 그걸 쓰고, 없으면 거리/시간으로 구한다.
    final speed = pos.speed > 0 ? pos.speed : meters / dt;
    return WalkStep(meters: meters, metersPerSecond: speed);
  }
}
