import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// 기상청 초단기예보 조회 결과.
class KmaWeather {
  const KmaWeather({required this.celsius, required this.icon});

  final int celsius;

  /// 하늘상태·강수형태를 합쳐 고른 이모지.
  final String icon;

  String get temperatureLabel => '$celsius℃';
}

/// 기상청 단기예보 API(공공데이터포털) 클라이언트.
///
/// 초단기예보(getUltraSrtFcst) 한 번만 호출해서 기온(T1H)·하늘상태(SKY)·
/// 강수형태(PTY)를 함께 받는다. 실황(getUltraSrtNcst)에는 SKY가 없어서
/// 이모지를 고르려면 어차피 예보를 봐야 하므로 호출을 하나로 합쳤다.
///
/// ## 서비스 키
/// `--dart-define=KMA_API_KEY=...` 로 주입한다(저장소에 키를 넣지 않는다).
/// 공공데이터포털에서 주는 **디코딩된** 키를 넣어야 한다 — 인코딩된 키를 넣으면
/// [Uri]가 한 번 더 인코딩해서 인증에 실패한다.
///
/// 앱(Android·iOS) 기준이다. 개발 중 `-d chrome`으로 띄우면 data.go.kr이
/// CORS 헤더를 안 줘서 브라우저가 막으니, 기온 확인은 실기기에서 한다.
/// 실패하면 예외를 던지고 호출부가 기본값으로 폴백한다.
class KmaWeatherApi {
  KmaWeatherApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String apiKey = String.fromEnvironment('KMA_API_KEY');
  static bool get hasKey => apiKey.isNotEmpty;

  static const _host = 'apis.data.go.kr';
  static const _path =
      '/1360000/VilageFcstInfoService_2.0/getUltraSrtFcst';

  Future<KmaWeather> fetch({
    required double lat,
    required double lon,
    DateTime? now,
  }) async {
    if (!hasKey) {
      throw StateError('KMA_API_KEY가 없습니다 (--dart-define으로 주입)');
    }
    final grid = KmaGrid.fromLatLon(lat, lon);
    final base = _baseDateTime(now ?? DateTime.now());

    final uri = Uri.https(_host, _path, {
      'serviceKey': apiKey,
      'pageNo': '1',
      // 6시간치 예보 × 항목 수. 가장 이른 시각만 쓰지만 넉넉히 받아둔다.
      'numOfRows': '60',
      'dataType': 'JSON',
      'base_date': base.date,
      'base_time': base.time,
      'nx': '${grid.nx}',
      'ny': '${grid.ny}',
    });

    // 공공데이터포털은 응답이 느릴 때가 많아 넉넉히 잡는다(짧으면 자주 끊긴다).
    final res = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw http.ClientException('기상청 응답 ${res.statusCode}', uri);
    }
    return _parse(res.body);
  }

  KmaWeather _parse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final header =
        (json['response']?['header']) as Map<String, dynamic>? ?? const {};
    if (header['resultCode'] != '00') {
      throw StateError('기상청 오류: ${header['resultMsg'] ?? '알 수 없음'}');
    }
    final items =
        (json['response']?['body']?['items']?['item'] as List?) ?? const [];
    if (items.isEmpty) throw StateError('기상청 예보 항목이 비어 있습니다');

    // 가장 이른 예보시각 = "지금"에 가장 가까운 값.
    String? earliest;
    for (final raw in items) {
      final t = (raw as Map)['fcstTime'] as String?;
      if (t != null && (earliest == null || t.compareTo(earliest) < 0)) {
        earliest = t;
      }
    }

    int? temp, sky, pty;
    for (final raw in items) {
      final m = raw as Map;
      if (m['fcstTime'] != earliest) continue;
      final value = int.tryParse('${m['fcstValue']}');
      switch (m['category']) {
        case 'T1H':
          temp = value;
        case 'SKY':
          sky = value;
        case 'PTY':
          pty = value;
      }
    }
    if (temp == null) throw StateError('기온(T1H)이 응답에 없습니다');

    return KmaWeather(celsius: temp, icon: _icon(sky: sky, pty: pty));
  }

  /// PTY(강수형태)가 우선, 없으면 SKY(하늘상태).
  /// PTY 0없음 1비 2비/눈 3눈 5빗방울 6빗방울눈날림 7눈날림 / SKY 1맑음 3구름많음 4흐림.
  static String _icon({int? sky, int? pty}) {
    switch (pty) {
      case 1:
      case 5:
        return '🌧️';
      case 2:
      case 6:
        return '🌨️';
      case 3:
      case 7:
        return '❄️';
    }
    return switch (sky) {
      3 => '⛅',
      4 => '☁️',
      _ => '☀️',
    };
  }

  /// 초단기예보 base_time 규칙: 매시 30분 발표, 45분부터 조회 가능.
  /// 45분 전이면 한 시간 전 발표분을 쓴다.
  static ({String date, String time}) _baseDateTime(DateTime now) {
    var t = now;
    if (t.minute < 45) t = t.subtract(const Duration(hours: 1));
    final two = (int v) => v.toString().padLeft(2, '0');
    return (
      date: '${t.year}${two(t.month)}${two(t.day)}',
      time: '${two(t.hour)}30',
    );
  }
}

/// 위경도 → 기상청 격자(nx, ny). 기상청이 배포한 LCC(Lambert) 변환 그대로다.
class KmaGrid {
  const KmaGrid(this.nx, this.ny);

  final int nx;
  final int ny;

  // 격자 정의 상수 (기상청 제공값).
  static const _re = 6371.00877; // 지구 반경(km)
  static const _grid = 5.0; // 격자 간격(km)
  static const _slat1 = 30.0; // 표준위도 1
  static const _slat2 = 60.0; // 표준위도 2
  static const _olon = 126.0; // 기준점 경도
  static const _olat = 38.0; // 기준점 위도
  static const _xo = 43.0; // 기준점 X좌표
  static const _yo = 136.0; // 기준점 Y좌표

  static KmaGrid fromLatLon(double lat, double lon) {
    const degrad = math.pi / 180.0;
    final re = _re / _grid;
    final slat1 = _slat1 * degrad;
    final slat2 = _slat2 * degrad;
    final olon = _olon * degrad;
    final olat = _olat * degrad;

    var sn = math.tan(math.pi * 0.25 + slat2 * 0.5) /
        math.tan(math.pi * 0.25 + slat1 * 0.5);
    sn = math.log(math.cos(slat1) / math.cos(slat2)) / math.log(sn);
    var sf = math.tan(math.pi * 0.25 + slat1 * 0.5);
    sf = math.pow(sf, sn) * math.cos(slat1) / sn;
    var ro = math.tan(math.pi * 0.25 + olat * 0.5);
    ro = re * sf / math.pow(ro, sn);

    var ra = math.tan(math.pi * 0.25 + lat * degrad * 0.5);
    ra = re * sf / math.pow(ra, sn);
    var theta = lon * degrad - olon;
    if (theta > math.pi) theta -= 2.0 * math.pi;
    if (theta < -math.pi) theta += 2.0 * math.pi;
    theta *= sn;

    return KmaGrid(
      (ra * math.sin(theta) + _xo + 0.5).floor(),
      (ro - ra * math.cos(theta) + _yo + 0.5).floor(),
    );
  }

  @override
  String toString() => 'KmaGrid($nx, $ny)';
}
