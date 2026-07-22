/// 산책 기록 도메인.
///
/// 발자국은 **오늘 누적 걸음 수**를 단계별 표에 넣어 정해진다.
class WalkMath {
  WalkMath._();

  /// 산책 중 게이지의 최대 걸음 수(하루 기준). 눈금: 3천/6천/9천/1만2천/1만5천.
  static const int dailyMaxSteps = 15000;

  /// 하루에 받을 수 있는 최대 발자국.
  static const int dailyMaxPaws = 150;

  /// 보상을 받으려면 최소 이만큼은 걸어야 한다(걸음). 첫 단계(1,000보) 미만이면 0.
  static const int rewardMinSteps = 1000;

  /// 하루 누적 걸음 수 → 그날 받을 수 있는 발자국 **총량**(단계별).
  /// 1천:10 / 3천:30 / 5천:60 / 8천:100 / 1만:130 / 1만5천+:150.
  static int rewardForSteps(int steps) {
    if (steps >= 15000) return 150;
    if (steps >= 10000) return 130;
    if (steps >= 8000) return 100;
    if (steps >= 5000) return 60;
    if (steps >= 3000) return 30;
    if (steps >= 1000) return 10;
    return 0;
  }

  /// 지금 "보상 받기"로 받을 발자국 = (오늘 걸음의 총 발자국) − (이미 받은 발자국).
  static int claimablePaws({required int todaySteps, required int todayPaws}) {
    final left = rewardForSteps(todaySteps) - todayPaws;
    return left < 0 ? 0 : left;
  }

  /// 애니메이션 배속의 기준 속도(m/s). 보통 걷기(약 5km/h)에서 1.0배가 된다.
  static const double referenceSpeed = 1.4;

  /// 이 배속부터 "달리기"로 본다. 그보다 느리면 홈과 같은 걷기 모션을 쓴다.
  static const double runThreshold = 1.2;

  /// 평균 보폭(m). 걸음 센서가 없을 때 GPS 거리에서 걸음 수를 어림잡는 용도.
  static const double metersPerStep = 0.72;

  static int estimatedSteps(double meters) => (meters / metersPerStep).round();

  /// 지금 이동 속도 → 화면 배속.
  ///
  /// 거리가 빨리 늘면 강아지도 배경도 빨라지고, 느려지면 같이 느려진다.
  /// 멈추면 0을 돌려주고, 화면은 그때 애니메이션을 세운다.
  static double paceFactor(double metersPerSecond) {
    if (metersPerSecond <= 0.15) return 0;
    return (metersPerSecond / referenceSpeed).clamp(0.35, 4.5);
  }
}

/// 진행 중이거나 방금 끝난 한 번의 산책.
class WalkSession {
  const WalkSession({
    this.meters = 0,
    this.seconds = 0,
    this.metersPerSecond = 0,
    this.startedAt,
    this.measuredSteps,
  });

  /// 걸음 센서로 실측한 걸음 수. 센서를 못 쓰면 null이고, 그때는 거리에서
  /// 어림잡은 [estimatedSteps]가 대신 쓰인다.
  final int? measuredSteps;

  /// GPS로 누적한 이동 거리(m).
  final double meters;

  /// 시작한 시각. 경과 시간은 tick을 세지 않고 **이 시각과의 차이**로 구한다.
  /// 화면이 꺼져 타이머가 멈춰 있어도 다시 켰을 때 시간이 정확히 맞는다.
  final DateTime? startedAt;

  final int seconds;

  /// 지금 이동 속도(m/s). 화면 배속([pace])의 근거.
  final double metersPerSecond;

  double get km => meters / 1000;

  /// 거리에서 어림잡은 걸음 수(실측 아님).
  int get estimatedSteps => WalkMath.estimatedSteps(meters);

  /// 이번 산책의 걸음 수. 센서 값이 있으면 그걸 쓰고, 없으면 거리에서 어림잡는다.
  int get steps => measuredSteps ?? estimatedSteps;

  /// 강아지·배경·먼지가 공유하는 배속. 1.0이 보통 걷기.
  double get pace => WalkMath.paceFactor(metersPerSecond);

  /// 빠르면 달리기 스프라이트, 느리면 홈과 같은 걷기 모션.
  bool get isRunning => pace >= WalkMath.runThreshold;

  WalkSession copyWith({
    double? meters,
    int? seconds,
    double? metersPerSecond,
    DateTime? startedAt,
    int? measuredSteps,
  }) => WalkSession(
    meters: meters ?? this.meters,
    seconds: seconds ?? this.seconds,
    metersPerSecond: metersPerSecond ?? this.metersPerSecond,
    startedAt: startedAt ?? this.startedAt,
    measuredSteps: measuredSteps ?? this.measuredSteps,
  );

  /// mm:ss (한 시간을 넘기면 h:mm:ss).
  String get elapsedLabel => formatElapsed(seconds);

  static String formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

/// 누적 기록: 오늘 걸은 양 + 이번 주에 산책한 요일.
///
/// 날짜가 바뀌면 오늘 기록이, 주가 바뀌면 요일 표시가 각각 초기화된다
/// ([rolled] 참고). 앱을 며칠 만에 다시 열어도 지난 기록이 오늘로 새지 않는다.
class WalkLog {
  const WalkLog({
    required this.day,
    required this.weekStart,
    this.todaySteps = 0,
    this.todayMeters = 0,
    this.todaySeconds = 0,
    this.todayPaws = 0,
    this.weekdays = const {},
  });

  /// [todayMeters]가 기록된 날짜(자정 기준).
  final DateTime day;

  /// [weekdays]가 속한 주의 월요일(자정 기준).
  final DateTime weekStart;

  /// 오늘 누적 걸음 수(발자국 지급·게이지의 기준).
  final int todaySteps;

  final double todayMeters;
  final int todaySeconds;

  /// 오늘 산책으로 실제 지급받은 발자국. 보상을 안 받고 끝낸 산책은 빠진다.
  final int todayPaws;

  /// 이번 주에 산책한 요일 (1=월 … 7=일).
  final Set<int> weekdays;

  double get todayKm => todayMeters / 1000;

  static DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  static DateTime weekStartOf(DateTime t) =>
      dayOf(t).subtract(Duration(days: t.weekday - 1));

  factory WalkLog.empty(DateTime now) =>
      WalkLog(day: dayOf(now), weekStart: weekStartOf(now));

  /// [now] 기준으로 날짜·주가 지났으면 해당 부분만 비운 기록을 돌려준다.
  WalkLog rolled(DateTime now) {
    final today = dayOf(now);
    final week = weekStartOf(now);
    if (today == day && week == weekStart) return this;
    return WalkLog(
      day: today,
      weekStart: week,
      todaySteps: today == day ? todaySteps : 0,
      todayMeters: today == day ? todayMeters : 0,
      todaySeconds: today == day ? todaySeconds : 0,
      todayPaws: today == day ? todayPaws : 0,
      weekdays: week == weekStart ? weekdays : const {},
    );
  }

  /// 끝난 산책 한 건을 누적한다. [paws]는 실제로 지급한 발자국.
  WalkLog merge(WalkSession session, {required int paws, required DateTime at}) {
    final base = rolled(at);
    return WalkLog(
      day: base.day,
      weekStart: base.weekStart,
      todaySteps: base.todaySteps + session.steps,
      todayMeters: base.todayMeters + session.meters,
      todaySeconds: base.todaySeconds + session.seconds,
      todayPaws: base.todayPaws + paws,
      weekdays: {...base.weekdays, at.weekday},
    );
  }

  Map<String, dynamic> toMap() => {
    'day': day.millisecondsSinceEpoch,
    'weekStart': weekStart.millisecondsSinceEpoch,
    'todaySteps': todaySteps,
    'todayMeters': todayMeters,
    'todaySeconds': todaySeconds,
    'todayPaws': todayPaws,
    'weekdays': weekdays.toList(),
  };

  factory WalkLog.fromMap(Map<dynamic, dynamic> m, DateTime now) {
    DateTime read(String key, DateTime fallback) {
      final v = m[key];
      return v is num
          ? DateTime.fromMillisecondsSinceEpoch(v.toInt())
          : fallback;
    }

    final meters = (m['todayMeters'] as num?)?.toDouble() ?? 0;
    // 걸음 저장본이 없던 구버전은 거리에서 어림잡아 채운다.
    final steps = (m['todaySteps'] as num?)?.toInt() ??
        WalkMath.estimatedSteps(meters);

    return WalkLog(
      day: read('day', dayOf(now)),
      weekStart: read('weekStart', weekStartOf(now)),
      todaySteps: steps,
      todayMeters: meters,
      todaySeconds: (m['todaySeconds'] as num?)?.toInt() ?? 0,
      todayPaws: (m['todayPaws'] as num?)?.toInt() ?? 0,
      weekdays:
          (m['weekdays'] as List?)
              ?.map((e) => (e as num).toInt())
              .toSet() ??
          const {},
    );
  }
}
