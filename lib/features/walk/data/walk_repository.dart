import 'package:hive_flutter/hive_flutter.dart';

import '../domain/walk_log.dart';

/// 산책 누적 기록을 Hive 박스에 Map으로 영속화한다. (펫 박스와 분리)
class WalkRepository {
  WalkRepository(this._box);

  final Box _box;
  static const _key = 'walk_log';

  static Future<WalkRepository> open() async {
    final box = await Hive.openBox('walk_box');
    return WalkRepository(box);
  }

  /// 저장된 기록을 [now] 기준으로 롤오버해서 돌려준다(없으면 빈 기록).
  WalkLog load(DateTime now) {
    final raw = _box.get(_key);
    if (raw is Map) return WalkLog.fromMap(raw, now).rolled(now);
    return WalkLog.empty(now);
  }

  Future<void> save(WalkLog log) async => _box.put(_key, log.toMap());

  Future<void> clear() async => _box.delete(_key);

  // ── 진행 중인 산책 ──
  // 화면이 꺼지거나 OS가 앱을 정리해도 지금까지 잰 거리를 잃지 않도록
  // 시작 시각과 누적 거리를 남겨 둔다.
  static const _activeKey = 'walk_active';

  ({DateTime startedAt, double meters})? loadActive() {
    final raw = _box.get(_activeKey);
    if (raw is! Map) return null;
    final ms = (raw['startedAt'] as num?)?.toInt();
    if (ms == null) return null;
    return (
      startedAt: DateTime.fromMillisecondsSinceEpoch(ms),
      meters: (raw['meters'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<void> saveActive({
    required DateTime startedAt,
    required double meters,
  }) async => _box.put(_activeKey, {
    'startedAt': startedAt.millisecondsSinceEpoch,
    'meters': meters,
  });

  Future<void> clearActive() async => _box.delete(_activeKey);
}
