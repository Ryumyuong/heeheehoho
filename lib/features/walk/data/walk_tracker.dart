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
  _Pt? _last;

  /// 좌표를 부드럽게 만드는 칼만 필터(위경도 각각). raw 좌표의 지그재그를 줄여
  /// 거리 과다 측정을 완화한다.
  _KalmanLatLng _kalman = _KalmanLatLng();

  /// 이 값보다 오차가 큰 위치는 버린다(m). 너무 크면 제자리에서도 좌표가 튄다.
  static const double _maxAccuracy = 30;

  /// 이 거리보다 짧은 이동은 GPS 흔들림으로 본다(m).
  /// 제자리에 서 있을 때 좌표가 흔들려 거리가 늘지 않도록 넉넉히 잡는다.
  static const double _minMove = 6;

  /// 사람이 낼 수 없는 속도(m/s). 이보다 빠른 점프는 튄 좌표로 본다.
  static const double _maxSpeed = 8;

  /// GPS가 "멈춰 있음"으로 볼 속도(m/s). 도플러 속도가 이보다 느리면 실제로
  /// 이동한 게 아니라 좌표 노이즈로 보고 거리에 넣지 않는다(속도 교차검증).
  static const double _minSpeed = 0.4;

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
    _kalman = _KalmanLatLng(); // 새 산책이면 필터도 초기화
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
    // distanceFilter: 이만큼 움직여야 이벤트가 온다. 값이 작으면 GPS 노이즈가
    // 지그재그로 누적돼 실제보다 거리가 부풀려진다. 조금 크게 잡아 과다 측정을
    // 줄인다(대신 달리기·정지 반응은 몇 미터 늦어진다).
    const filter = 10;
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

    // ① 칼만 필터로 좌표를 매끄럽게(지그재그 제거).
    final sm = _kalman.process(
      pos.latitude,
      pos.longitude,
      pos.accuracy,
      pos.timestamp.millisecondsSinceEpoch,
    );

    final prev = _last;
    if (prev == null) {
      _last = _Pt(sm.lat, sm.lng, pos.timestamp);
      return null; // 첫 점은 기준만 잡는다.
    }

    final meters = Geolocator.distanceBetween(
      prev.lat,
      prev.lng,
      sm.lat,
      sm.lng,
    );
    final dt = pos.timestamp.difference(prev.time).inMilliseconds / 1000;
    if (dt <= 0) return null;

    // ② 속도 교차검증: GPS 도플러 속도가 실제 이동을 뒷받침할 때만 인정한다.
    // (좌표는 흔들려도 도플러 속도는 정지 시 0에 가깝다 → 제자리 노이즈 차단)
    final gpsSpeed = pos.speed; // m/s (Doppler)
    final segSpeed = meters / dt;
    if (segSpeed > _maxSpeed) {
      _last = _Pt(sm.lat, sm.lng, pos.timestamp); // 튄 좌표: 기준만 옮김
      return null;
    }
    if (meters < _minMove) return null; // 미세 흔들림
    // 도플러 속도가 유효하면 그걸로 정지 여부를 가른다.
    if (gpsSpeed >= 0 && gpsSpeed < _minSpeed && segSpeed < _minSpeed) {
      return null; // 실제로는 멈춰 있음
    }

    _last = _Pt(sm.lat, sm.lng, pos.timestamp);
    final speed = gpsSpeed > 0 ? gpsSpeed : segSpeed;
    return WalkStep(meters: meters, metersPerSecond: speed);
  }
}

/// 필터를 거친 좌표 한 점(시각 포함).
class _Pt {
  const _Pt(this.lat, this.lng, this.time);
  final double lat;
  final double lng;
  final DateTime time;
}

/// 위경도용 간단 칼만 필터. GPS 정확도(m)를 측정 잡음으로 써서, 좌표가 흔들릴
/// 때는 이전 추정에 더 무게를 두고 매끄럽게 이어준다.
///
/// 참고: 안드로이드 위치 스무딩에서 널리 쓰는 1D 근사(위·경도 독립).
class _KalmanLatLng {
  double? _lat;
  double? _lng;
  double _variance = -1; // <0 이면 초기화 전
  int _timeMs = 0;

  /// 이동체가 초당 만들어내는 불확실성(m²/s). 클수록 새 좌표를 더 믿는다.
  static const double _q = 3.0;

  ({double lat, double lng}) process(
    double lat,
    double lng,
    double accuracy,
    int timeMs,
  ) {
    // 정확도(m)의 제곱을 측정 잡음으로 쓴다. 너무 좋게 나오면 하한을 둔다.
    final acc = accuracy < 1 ? 1.0 : accuracy;
    final r = acc * acc;

    if (_variance < 0) {
      _lat = lat;
      _lng = lng;
      _variance = r;
      _timeMs = timeMs;
      return (lat: _lat!, lng: _lng!);
    }

    // 예측: 시간이 지난 만큼 불확실성이 커진다.
    final dt = (timeMs - _timeMs) / 1000.0;
    if (dt > 0) {
      _variance += dt * _q;
      _timeMs = timeMs;
    }

    // 갱신: 칼만 이득으로 이전 추정과 새 측정을 섞는다.
    final k = _variance / (_variance + r);
    _lat = _lat! + k * (lat - _lat!);
    _lng = _lng! + k * (lng - _lng!);
    _variance *= (1 - k);
    return (lat: _lat!, lng: _lng!);
  }
}
