import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

/// OS 걸음 센서로 이번 산책의 걸음 수를 실측한다.
///
/// Android는 `TYPE_STEP_COUNTER`, iOS는 `CMPedometer`를 쓴다. 둘 다 **부팅(또는
/// 관측 시작) 이후 누적값**을 주므로, 산책을 시작할 때의 값을 기준점으로 잡고
/// 그 차이를 이번 산책의 걸음 수로 삼는다.
///
/// 센서는 OS·하드웨어가 세기 때문에 **화면이 꺼져 있어도 계속 쌓이고**,
/// 앱이 다시 깨어났을 때 늘어난 누적값이 한 번에 들어온다. 배터리도 거의 안 쓴다.
class StepCounter {
  StreamSubscription<StepCount>? _sub;

  /// 산책 시작 시점의 센서 누적값.
  int? _baseline;

  bool get isCounting => _sub != null;

  /// Android는 ACTIVITY_RECOGNITION 런타임 권한이 필요하다.
  /// iOS는 CMPedometer가 알아서 모션 권한을 묻는다(Info.plist 문구 필요).
  Future<bool> ensurePermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  /// 걸음 세기 시작. 값이 갱신될 때마다 [onSteps]에 **이번 산책의 걸음 수**가 온다.
  /// 시작하지 못하면 false(권한 거부·센서 없음·미지원 플랫폼).
  Future<bool> start(void Function(int steps) onSteps) async {
    await stop();
    if (!await ensurePermission()) return false;

    _baseline = null;
    try {
      _sub = Pedometer.stepCountStream.listen(
        (event) {
          // 첫 값이 기준점. 이후로는 늘어난 만큼이 이번 산책의 걸음 수다.
          _baseline ??= event.steps;
          final steps = event.steps - _baseline!;
          // 기기를 재부팅하면 누적값이 초기화돼 음수가 나올 수 있다.
          // 그때는 기준점을 다시 잡고 0부터 센다.
          if (steps < 0) {
            _baseline = event.steps;
            onSteps(0);
            return;
          }
          onSteps(steps);
        },
        onError: (_) {
          // 센서가 없는 기기. 거리 기반 추정치로 폴백된다.
        },
        cancelOnError: false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _baseline = null;
  }
}
