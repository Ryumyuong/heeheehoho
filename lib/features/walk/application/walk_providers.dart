import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pet/application/pet_providers.dart';
import '../data/kma_weather_api.dart';
import '../data/location_service.dart';
import '../data/step_counter.dart';
import '../data/walk_repository.dart';
import '../data/walk_tracker.dart';
import '../dev_flags.dart';
import '../domain/walk_log.dart';

/// main()에서 override 주입.
final walkRepositoryProvider = Provider<WalkRepository>(
  (ref) => throw UnimplementedError('walkRepositoryProvider must be overridden'),
);

/// 산책 화면의 세 단계: 시작 전 / 산책 화면 / 결과.
enum WalkPhase { ready, walking, finished }

/// 산책 화면 안에서의 진행 상태.
///
/// 시작 전(standby) → 재는 중(running) → 종료(stopped) 순서로 가고,
/// **stopped가 되어야 "보상 받기"가 열린다.** 종료해도 화면에 남아 있어서
/// 이어 걷고 싶으면 다시 시작할 수 있다.
enum WalkRun { standby, running, stopped }

/// 산책 중 화면 좌상단에 띄우는 현재 지역·날씨.
class WalkWeather {
  const WalkWeather({
    required this.place,
    required this.temperature,
    required this.icon,
  });

  final String place; // 예: 부산광역시
  final String temperature; // 예: 23℃
  final String icon; // 날씨 이모지

  /// 아직 위치를 못 받은 동안.
  static const loading = WalkWeather(
    place: '위치 확인 중',
    temperature: '--℃',
    icon: '☀️',
  );

  /// 위치 권한이 없거나 위치 서비스가 꺼진 경우.
  static const unavailable = WalkWeather(
    place: '위치 정보 없음',
    temperature: '--℃',
    icon: '☀️',
  );
}

final locationServiceProvider = Provider((ref) => LocationService());
final kmaWeatherApiProvider = Provider((ref) => KmaWeatherApi());
final walkTrackerProvider = Provider((ref) => WalkTracker());
final stepCounterProvider = Provider((ref) => StepCounter());

/// 현재 지역 + 기상청 초단기예보.
///
/// 어느 단계에서 실패해도 화면이 비지 않도록 단계별로 폴백한다.
/// 위치 O·날씨 X면 지역명만 보여주고 기온은 `--℃`로 남긴다.
///
/// 날씨 조회에는 `--dart-define-from-file=env.json`의 KMA_API_KEY가 필요하다.
/// 개발 중 크롬으로 띄우면 CORS 때문에 기온은 안 나오고 지역명만 나온다.
final walkWeatherProvider = FutureProvider<WalkWeather>((ref) async {
  final UserPlace place;
  try {
    place = await ref.read(locationServiceProvider).current();
  } catch (_) {
    return WalkWeather.unavailable;
  }

  // 공공데이터포털은 가끔 느리거나 일시적으로 실패한다. 한 번 실패하면 앱을 껐다
  // 켜기 전까지 '--℃'로 남으므로, 몇 번 다시 시도해 스스로 복구되게 한다.
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      final w = await ref
          .read(kmaWeatherApiProvider)
          .fetch(lat: place.lat, lon: place.lon);
      return WalkWeather(
        place: place.name,
        temperature: w.temperatureLabel,
        icon: w.icon,
      );
    } catch (_) {
      if (attempt < 2) await Future.delayed(const Duration(seconds: 2));
    }
  }
  // 끝내 실패하면 지역만 보여주고 기온은 비워둔다.
  return WalkWeather(
    place: place.name,
    temperature: WalkWeather.loading.temperature,
    icon: WalkWeather.loading.icon,
  );
});

class WalkState {
  const WalkState({
    required this.log,
    this.phase = WalkPhase.ready,
    this.session = const WalkSession(),
    this.run = WalkRun.standby,
    this.simulated = false,
    this.rewardedPaws = 0,
  });

  final WalkPhase phase;

  /// 산책 화면 안에서의 진행 상태(대기 / 재는 중 / 종료).
  final WalkRun run;

  bool get running => run == WalkRun.running;

  /// 오늘 누적 걸음(이전 산책 + 이번 산책).
  int get todaySteps => log.todaySteps + session.steps;

  /// 지금 "보상 받기"로 받을 발자국(오늘 걸음 총 발자국 − 이미 받은 것).
  int get claimablePaws => WalkMath.claimablePaws(
    todaySteps: todaySteps,
    todayPaws: log.todayPaws,
  );

  /// 종료했고 받을 발자국이 남아 있으면 보상을 받을 수 있다.
  bool get canClaim => run == WalkRun.stopped && claimablePaws > 0;

  /// GPS를 못 써서 시뮬레이션으로 도는 중인지(개발용).
  final bool simulated;

  /// 진행 중(또는 방금 끝난) 산책 한 건.
  final WalkSession session;

  /// 오늘/이번 주 누적 기록.
  final WalkLog log;

  /// 방금 끝난 산책에서 실제로 받은 발자국. 보상 없이 종료하면 0.
  final int rewardedPaws;

  WalkState copyWith({
    WalkPhase? phase,
    WalkSession? session,
    WalkLog? log,
    WalkRun? run,
    bool? simulated,
    int? rewardedPaws,
  }) => WalkState(
    phase: phase ?? this.phase,
    session: session ?? this.session,
    log: log ?? this.log,
    run: run ?? this.run,
    simulated: simulated ?? this.simulated,
    rewardedPaws: rewardedPaws ?? this.rewardedPaws,
  );
}

/// 산책 진행/기록 컨트롤러.
///
/// 거리는 [WalkTracker](GPS)가 재고, 이 컨트롤러는 그걸 누적·저장한다.
/// 화면이 꺼져 있는 동안에도 위치는 계속 들어오므로 거리가 이어서 쌓이고,
/// 경과 시간은 tick이 아니라 시작 시각과의 차이로 구하므로 정확하다.
class WalkController extends Notifier<WalkState> {
  Timer? _ticker;

  /// 속도 표시가 툭툭 끊기지 않도록, 마지막으로 움직인 시각을 들고 있는다.
  DateTime? _lastMoveAt;

  // ── 개발용 시뮬레이션 ──
  // GPS를 못 쓰는 환경(크롬·에뮬레이터)에서 화면을 확인하려고 남겨둔 경로.
  // 화면을 탭할 때마다 걷기 → 뛰기 → 더 빨리 뛰기로 순환한다. 실기기에서는 안 쓴다.
  static const List<double> _simSpeeds = [
    1.4, // 보통 걷기 (걷기 모션)
    4.2, // 뛰기
    6.3, // 더 빨리 뛰기
  ];
  int _speedLevel = 0;
  double get _simSpeed => _simSpeeds[_speedLevel];

  @override
  WalkState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      ref.read(walkTrackerProvider).stop();
      ref.read(stepCounterProvider).stop();
    });

    final repo = ref.read(walkRepositoryProvider);
    final now = DateTime.now();
    return WalkState(log: repo.load(now));
  }

  /// 산책 화면 열기. 아직 재지는 않고 "산책 시작"을 기다린다.
  void open() {
    state = state.copyWith(
      phase: WalkPhase.walking,
      run: WalkRun.standby,
      session: const WalkSession(),
      rewardedPaws: 0,
      log: state.log.rolled(DateTime.now()),
    );
  }

  /// 산책 시작. 탭을 옮기거나 화면이 꺼져도 계속 쌓인다.
  /// 종료했다가 다시 시작하면 지금까지 잰 거리에 **이어서** 쌓인다.
  Future<void> begin() async {
    if (state.running) return;
    final now = DateTime.now();
    // 이어 걷는 경우엔 처음 시작한 시각을 유지해 경과 시간이 되감기지 않게 한다.
    final startedAt = state.session.startedAt ?? now;
    _speedLevel = 0;
    _lastMoveAt = now;
    state = state.copyWith(
      phase: WalkPhase.walking,
      run: WalkRun.running,
      session: state.session.copyWith(startedAt: startedAt),
      rewardedPaws: 0,
      log: state.log.rolled(now),
    );

    // 개발용 스위치가 켜져 있으면 GPS를 아예 안 쓴다(제자리에서도 거리가 는다).
    final started =
        kSimulateWalk ? false : await ref.read(walkTrackerProvider).start(_onMoved);
    state = state.copyWith(simulated: !started);

    // 걸음 수는 거리와 별개로 OS 걸음 센서가 실측한다.
    // 센서가 없거나 권한을 거부하면 measuredSteps가 계속 null이고,
    // 화면에는 거리에서 어림잡은 걸음 수가 나온다.
    if (!kSimulateWalk) await ref.read(stepCounterProvider).start(_onSteps);

    await ref.read(walkRepositoryProvider).saveActive(
      startedAt: startedAt,
      meters: state.session.meters,
    );

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// 산책 종료. 재기만 멈추고 화면에는 그대로 남는다.
  /// 여기서부터 "보상 받기"가 열리고, 원하면 다시 시작해서 이어 걸을 수 있다.
  Future<void> stop() async {
    if (!state.running) return;
    _ticker?.cancel();
    _ticker = null;
    await ref.read(walkTrackerProvider).stop();
    await ref.read(stepCounterProvider).stop();
    state = state.copyWith(
      run: WalkRun.stopped,
      // 멈췄으니 강아지·배경도 선다.
      session: state.session.copyWith(metersPerSecond: 0),
    );
  }

  /// GPS가 이동을 알려올 때마다 거리를 더한다.
  void _onMoved(WalkStep step) {
    if (!state.running) return;
    _lastMoveAt = DateTime.now();
    final s = state.session;
    final meters = s.meters + step.meters;
    state = state.copyWith(
      session: s.copyWith(
        meters: meters,
        metersPerSecond: step.metersPerSecond,
      ),
    );
    ref.read(walkRepositoryProvider).saveActive(
      startedAt: s.startedAt ?? DateTime.now(),
      meters: meters,
    );
  }

  /// 걸음 센서가 알려오는 이번 산책의 걸음 수.
  void _onSteps(int steps) {
    if (!state.running) return;
    state = state.copyWith(session: state.session.copyWith(measuredSteps: steps));
  }

  /// 1초마다 경과 시간을 갱신한다. 거리는 GPS가 채우므로 여기서 건드리지 않는다
  /// (시뮬레이션일 때만 예외).
  void _tick() {
    final s = state.session;
    final startedAt = s.startedAt;
    if (!state.running || startedAt == null) return;

    final now = DateTime.now();
    final seconds = now.difference(startedAt).inSeconds;

    if (state.simulated) {
      final meters = s.meters + _simSpeed;
      state = state.copyWith(
        session: s.copyWith(
          seconds: seconds,
          meters: meters,
          metersPerSecond: _simSpeed,
        ),
      );
      return;
    }

    // 한동안 이동 신호가 없으면 멈춘 것으로 보고 애니메이션을 세운다.
    final idle = now.difference(_lastMoveAt ?? now).inSeconds >= 6;
    state = state.copyWith(
      session: s.copyWith(
        seconds: seconds,
        metersPerSecond: idle ? 0 : s.metersPerSecond,
      ),
    );
  }

  /// 개발용 속도 순환(걷기 → 뛰기 → 더 빨리 → 걷기). 시뮬레이션 중일 때만 의미가 있다.
  void toggleSpeed() {
    if (!state.simulated || !state.running) return;
    _speedLevel = (_speedLevel + 1) % _simSpeeds.length;
    state = state.copyWith(
      session: state.session.copyWith(metersPerSecond: _simSpeed),
    );
  }

  /// 보상 받기. 산책을 마무리하고 결과 화면으로 넘어간다.
  /// 오늘 누적 걸음 수의 단계별 발자국에서 이미 받은 몫을 뺀 만큼 지급한다.
  Future<void> claim() async {
    _ticker?.cancel();
    _ticker = null;
    await ref.read(walkTrackerProvider).stop();
    await ref.read(stepCounterProvider).stop();

    final session = state.session;
    final now = DateTime.now();
    final today = state.log.rolled(now);
    // 이번 산책까지 합친 오늘 걸음의 총 발자국 − 이미 받은 발자국.
    final paws = WalkMath.claimablePaws(
      todaySteps: today.todaySteps + session.steps,
      todayPaws: today.todayPaws,
    );

    final log = state.log.merge(session, paws: paws, at: now);
    final repo = ref.read(walkRepositoryProvider);
    await repo.save(log);
    await repo.clearActive();
    if (paws > 0) await ref.read(petProvider.notifier).addPaws(paws);

    state = state.copyWith(
      phase: WalkPhase.finished,
      run: WalkRun.standby,
      log: log,
      rewardedPaws: paws,
    );
  }

  /// 산책 화면(대기/진행/종료) → 첫 화면으로.
  /// 재는 중이었다면 추적을 멈추고 진행 중 기록을 버린다(보상 없이 나가기).
  Future<void> exitToStart() async {
    _ticker?.cancel();
    _ticker = null;
    await ref.read(walkTrackerProvider).stop();
    await ref.read(stepCounterProvider).stop();
    await ref.read(walkRepositoryProvider).clearActive();
    reset();
  }

  /// 결과 화면 → 시작 화면으로.
  void reset() => state = state.copyWith(
    phase: WalkPhase.ready,
    run: WalkRun.standby,
    session: const WalkSession(),
    rewardedPaws: 0,
  );
}

final walkProvider = NotifierProvider<WalkController, WalkState>(
  WalkController.new,
);
