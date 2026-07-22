import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../dev_flags.dart';

/// 현재 위치와 그 위치의 행정구역명.
class UserPlace {
  const UserPlace({
    required this.lat,
    required this.lon,
    required this.name,
  });

  final double lat;
  final double lon;

  /// 시·도 단위 이름. 예: 부산광역시
  final String name;
}


/// 위치 권한을 받고 현재 좌표·지역명을 알아낸다.
class LocationService {
  /// 권한을 확인·요청한 뒤 현재 위치를 돌려준다.
  /// 권한이 없거나 위치 서비스가 꺼져 있으면 예외를 던진다.
  Future<UserPlace> current() async {
    // 개발 중에는 고정 위치를 쓴다(권한·GPS 없이 날씨 확인 가능).
    if (kFixedPlace case final fixed?) return fixed;

    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('위치 권한이 거부되었습니다');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        // 날씨·지역명 용도라 동네 수준이면 충분하다. 정밀도를 낮추면 훨씬 빠르고
        // 배터리도 덜 쓴다.
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 12),
      ),
    );

    return UserPlace(
      lat: pos.latitude,
      lon: pos.longitude,
      name: await _placeName(pos.latitude, pos.longitude),
    );
  }

  /// 좌표 → 시·도 이름.
  ///
  /// 앱에서는 geocoding으로 정확한 행정구역명이 나온다. 조회가 실패하거나
  /// (개발 중 크롬처럼) geocoding을 못 쓰는 환경이면 아래 시·도 대표 좌표 중
  /// 가장 가까운 곳으로 근사한다 — 경계 근처는 틀릴 수 있는 폴백일 뿐이다.
  /// 동·읍·면 단위까지 필요해지면 카카오 로컬 API 같은 국내 리버스
  /// 지오코딩으로 이 메서드만 갈아끼우면 된다.
  Future<String> _placeName(double lat, double lon) async {
    if (!kIsWeb) {
      try {
        // 결과를 한국어 행정구역명으로 받는다("Busan" 대신 "부산광역시").
        await geo.setLocaleIdentifier('ko_KR');
        final marks = await geo.placemarkFromCoordinates(lat, lon);
        final area = marks.firstOrNull?.administrativeArea;
        if (area != null && area.isNotEmpty) return area;
      } catch (_) {
        // 아래 근사 테이블로 폴백.
      }
    }
    return nearestProvince(lat, lon);
  }

  /// 17개 시·도 대표 좌표 중 가장 가까운 이름.
  static String nearestProvince(double lat, double lon) {
    var best = _provinces.first;
    var bestD = double.infinity;
    for (final p in _provinces) {
      // 위경도 차이의 제곱합이면 최근접 비교에는 충분하다(경도는 위도에 따라
      // 좁아지므로 cos 보정만 넣는다).
      final dLat = lat - p.lat;
      final dLon = (lon - p.lon) * math.cos(lat * math.pi / 180);
      final d = dLat * dLat + dLon * dLon;
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best.name;
  }

  static const _provinces = <({String name, double lat, double lon})>[
    (name: '서울특별시', lat: 37.5665, lon: 126.9780),
    (name: '부산광역시', lat: 35.1796, lon: 129.0756),
    (name: '대구광역시', lat: 35.8714, lon: 128.6014),
    (name: '인천광역시', lat: 37.4563, lon: 126.7052),
    (name: '광주광역시', lat: 35.1595, lon: 126.8526),
    (name: '대전광역시', lat: 36.3504, lon: 127.3845),
    (name: '울산광역시', lat: 35.5384, lon: 129.3114),
    (name: '세종특별자치시', lat: 36.4800, lon: 127.2890),
    (name: '경기도', lat: 37.4138, lon: 127.5183),
    (name: '강원특별자치도', lat: 37.8228, lon: 128.1555),
    (name: '충청북도', lat: 36.8000, lon: 127.7000),
    (name: '충청남도', lat: 36.5184, lon: 126.8000),
    (name: '전북특별자치도', lat: 35.7175, lon: 127.1530),
    (name: '전라남도', lat: 34.8679, lon: 126.9910),
    (name: '경상북도', lat: 36.4919, lon: 128.8889),
    (name: '경상남도', lat: 35.4606, lon: 128.2132),
    (name: '제주특별자치도', lat: 33.4996, lon: 126.5312),
  ];
}
