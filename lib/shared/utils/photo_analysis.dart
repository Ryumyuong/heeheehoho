import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/pixel_theme.dart';
import '../../features/pet/domain/pet.dart';

/// 사진에서 읽어낸 강아지 특징. 커스터마이즈 화면의 "시작점"으로만 쓴다.
///
/// [furColorValue]와 [bodyShape]는 사진에서 실제로 계산해 낸 값이고,
/// [mouthStyle]은 혀가 보일 때만 바뀐다. 눈·코 모양은 사진만으로는 알 수 없어
/// 손대지 않는다(기본값 유지) — 자세한 이유는 [analyzeDogPhoto] 참고.
class PhotoDogGuess {
  const PhotoDogGuess({
    required this.rawFur,
    required this.furColorValue,
    required this.bodyShape,
    required this.mouthStyle,
    required this.metrics,
  });

  /// 사진에서 뽑은 실제 털색(팔레트에 맞추기 전 원본). 미리보기·디버깅용.
  final Color rawFur;

  /// [AppColors.furColors] 중 가장 가까운 색.
  final int furColorValue;

  final BodyShape bodyShape;
  final MouthStyle mouthStyle;

  /// 판정에 쓴 원시 수치. 실제 사진들로 임계값을 다시 맞출 때 보라고 남겨둔다.
  final PhotoMetrics metrics;
}

/// [PhotoDogGuess]의 근거가 된 측정값.
class PhotoMetrics {
  const PhotoMetrics({
    required this.roughness,
    required this.aspect,
    required this.tongueRatio,
  });

  /// 표면 거칠기(이웃 픽셀 밝기 차 평균). 복슬복슬할수록 크다.
  final double roughness;

  /// 실루엣 가로/세로 비. 1보다 크면 옆으로 길다.
  final double aspect;

  /// 피사체 중 혀로 볼 만한 분홍·빨강 픽셀의 비율(0~1).
  final double tongueRatio;

  @override
  String toString() => 'roughness=${roughness.toStringAsFixed(1)} '
      'aspect=${aspect.toStringAsFixed(2)} '
      'tongue=${(tongueRatio * 100).toStringAsFixed(2)}%';
}

/// 강아지 사진을 분석해 외형 특징을 어림잡는다. 서버도 ML 모델도 쓰지 않는다.
///
/// 하는 일:
/// - **털색**: 네 귀퉁이로 배경색을 추정해 배경을 걷어내고, 가운데 영역에서 가장
///   넓은 면적을 차지한 색을 골라 팔레트 5색 중 가까운 색에 맞춘다.
/// - **몸 모양**: 배경을 뺀 실루엣의 가로세로 비율(길쭉하면 긴몸)과 표면의 거친
///   정도(털이 복슬거리면 윤곽 대비가 커진다)로 고른다.
/// - **입**: 얼굴 근처에 혀로 볼 만한 분홍/빨강 덩어리가 있으면 '혀내밀기'.
///
/// 하지 않는 일:
/// - **눈·코 모양**은 추정하지 않는다. 픽셀 통계만으로는 눈이 반짝이는지 졸린지,
///   코가 삼각인지 하트인지 구분할 근거가 없다. 진짜로 하려면 얼굴 랜드마크
///   모델(ML Kit/TFLite)을 붙여야 하고, 그전까지 찍어 맞히는 값은 사용자를
///   속이는 것에 가깝다. 기본값으로 두고 사용자가 고르게 한다.
///
/// 어디까지나 어림짐작이라 빗나갈 수 있으므로, 결과는 커스터마이즈 화면에서
/// 언제든 바꿀 수 있는 초기 선택으로만 쓴다. 분석 실패 시 null.
Future<PhotoDogGuess?> analyzeDogPhoto(Uint8List bytes) async {
  final img = await _decodeRgba(bytes);
  if (img == null) return null;

  final (:width, :height, :rgba) = img;
  final bg = _cornerAverage(rgba, width, height);

  // 배경과 다른 픽셀 = 피사체(강아지)로 본다. 배경을 못 잡으면 가운데 영역을
  // 통째로 피사체로 간주한다.
  bool isSubject(int x, int y) {
    final i = (y * width + x) * 4;
    if (rgba[i + 3] < 128) return false;
    if (bg == null) {
      return x > width * 0.2 &&
          x < width * 0.8 &&
          y > height * 0.15 &&
          y < height * 0.85;
    }
    return _rgbDistance(rgba[i], rgba[i + 1], rgba[i + 2], bg) >= 40;
  }

  final fur = _dominantColor(rgba, width, height, isSubject);
  if (fur == null) return null;

  final m = _measure(rgba, width, height, isSubject);

  return PhotoDogGuess(
    rawFur: fur,
    furColorValue: AppColors.furColors[_nearestPaletteIndex(fur)].toARGB32(),
    bodyShape: _pickBodyShape(m),
    mouthStyle:
        m.tongueRatio > _tongueThreshold ? MouthStyle.tongue : MouthStyle.smile,
    metrics: m,
  );
}

/// 혀로 인정할 최소 면적 비율. 혀는 몸 전체에서 차지하는 넓이가 생각보다 작아
/// (샘플 이미지 기준 0.6% 안팎) 문턱을 낮게 잡는다. 대신 이 근처에서는 판정이
/// 잘 흔들리므로, 빨간 목줄·장난감이 혀로 잡히면 올려야 한다.
const double _tongueThreshold = 0.004;

/// 복슬복슬로 볼 최소 거칠기. 사진 해상도·초점에 민감한 값이라, 실제 사진들로
/// [PhotoMetrics.roughness]를 찍어 보고 조정해야 한다.
const double _fluffyThreshold = 22;

/// 옆으로 길다고 볼 최소 가로세로 비.
const double _longThreshold = 1.35;

BodyShape _pickBodyShape(PhotoMetrics m) {
  if (m.roughness > _fluffyThreshold) return BodyShape.fluffy;
  return m.aspect > _longThreshold ? BodyShape.long : BodyShape.round;
}

/// 피사체 픽셀 중 가장 넓은 면적을 차지하는 색.
/// 4비트/채널(색당 16단계)로 뭉뚱그려 세서, 미세한 명암 차이는 한 덩어리로 본다.
Color? _dominantColor(
  Uint8List rgba,
  int w,
  int h,
  bool Function(int, int) isSubject,
) {
  final counts = <int, int>{};
  final sums = <int, List<int>>{};

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!isSubject(x, y)) continue;
      final i = (y * w + x) * 4;
      final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
      // 눈·코·그림자처럼 아주 어두운 픽셀은 털색으로 치지 않는다.
      // (검은 강아지도 보통 이보다는 밝게 찍혀 블랙으로 잡힌다)
      if (r < 28 && g < 28 && b < 28) continue;

      final key = (r >> 4) << 8 | (g >> 4) << 4 | (b >> 4);
      counts[key] = (counts[key] ?? 0) + 1;
      final s = sums[key] ??= [0, 0, 0];
      s[0] += r;
      s[1] += g;
      s[2] += b;
    }
  }
  if (counts.isEmpty) return null;

  var bestKey = counts.keys.first;
  var bestCount = 0;
  counts.forEach((k, c) {
    if (c > bestCount) {
      bestCount = c;
      bestKey = k;
    }
  });

  final s = sums[bestKey]!;
  return Color.fromARGB(
    255,
    (s[0] / bestCount).round(),
    (s[1] / bestCount).round(),
    (s[2] / bestCount).round(),
  );
}

/// 피사체를 한 번 훑어 실루엣 비율·표면 거칠기·혀 면적을 잰다.
///
/// 거칠기: 복슬복슬한 털은 윤곽이 잘게 튀어 이웃 픽셀 간 밝기 차가 커지고,
/// 매끈한 단모종은 작다.
/// 혀: 갈색 털에 걸리지 않도록 빨강이 초록보다 확실히 앞서는 픽셀만 센다.
PhotoMetrics _measure(
  Uint8List rgba,
  int w,
  int h,
  bool Function(int, int) isSubject,
) {
  var minX = w, maxX = -1, minY = h, maxY = -1;
  var roughSum = 0.0;
  var n = 0;
  var tongue = 0;

  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      if (!isSubject(x, y)) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      final i = (y * w + x) * 4;

      // 가로/세로 이웃과의 밝기 차 = 국소 대비.
      final l = _luma(rgba, i);
      roughSum += (l - _luma(rgba, (y * w + x + 1) * 4)).abs() +
          (l - _luma(rgba, ((y + 1) * w + x) * 4)).abs();
      n++;

      final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
      if (r > 150 && r - g > 60 && r - b > 50) tongue++;
    }
  }

  if (n == 0 || maxX < 0) {
    return const PhotoMetrics(roughness: 0, aspect: 1, tongueRatio: 0);
  }
  return PhotoMetrics(
    roughness: roughSum / n,
    aspect: (maxX - minX + 1) / (maxY - minY + 1),
    tongueRatio: tongue / n,
  );
}

double _luma(Uint8List rgba, int i) =>
    0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2];

typedef _Rgba = ({int width, int height, Uint8List rgba});

/// 가로 96px로 줄여 디코드. 색·형태 통계에는 이 정도면 충분하고 빠르다.
Future<_Rgba?> _decodeRgba(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 96);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final result = data == null
        ? null
        : (
            width: image.width,
            height: image.height,
            rgba: data.buffer.asUint8List(),
          );
    image.dispose();
    codec.dispose();
    return result;
  } catch (_) {
    return null; // 손상된 파일 등 — 호출부가 기본 외형으로 폴백.
  }
}

/// 네 귀퉁이 평균 = 배경색 어림값. 귀퉁이끼리 색이 제각각이면(배경이 복잡하면)
/// 배경 제거를 포기하고 null을 준다.
List<int>? _cornerAverage(Uint8List rgba, int w, int h) {
  final box = math.max(2, (math.min(w, h) * 0.08).round());
  final corners = [(0, 0), (w - box, 0), (0, h - box), (w - box, h - box)];

  final means = <List<int>>[];
  for (final (cx, cy) in corners) {
    var r = 0, g = 0, b = 0, n = 0;
    for (var y = cy; y < cy + box; y++) {
      for (var x = cx; x < cx + box; x++) {
        final i = (y * w + x) * 4;
        if (rgba[i + 3] < 128) continue;
        r += rgba[i];
        g += rgba[i + 1];
        b += rgba[i + 2];
        n++;
      }
    }
    if (n == 0) return null;
    means.add([r ~/ n, g ~/ n, b ~/ n]);
  }

  final avg = [
    means.map((m) => m[0]).reduce((a, b) => a + b) ~/ 4,
    means.map((m) => m[1]).reduce((a, b) => a + b) ~/ 4,
    means.map((m) => m[2]).reduce((a, b) => a + b) ~/ 4,
  ];
  for (final m in means) {
    if (_rgbDistance(m[0], m[1], m[2], avg) > 60) return null;
  }
  return avg;
}

double _rgbDistance(int r, int g, int b, List<int> o) {
  final dr = r - o[0], dg = g - o[1], db = b - o[2];
  return math.sqrt((dr * dr + dg * dg + db * db).toDouble());
}

/// 팔레트에서 가장 가까운 색. 사람 눈에 가까운 판단을 위해 Lab에서 비교한다.
/// (RGB로 재면 밝기 차가 과대평가돼 흰 강아지가 크림으로 새는 식의 오차가 난다)
int _nearestPaletteIndex(Color c) {
  final target = _toLab(c);
  var best = 0;
  var bestD = double.infinity;
  for (var i = 0; i < AppColors.furColors.length; i++) {
    final lab = _toLab(AppColors.furColors[i]);
    final d = math.sqrt(math.pow(target[0] - lab[0], 2) +
        math.pow(target[1] - lab[1], 2) +
        math.pow(target[2] - lab[2], 2));
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}

/// sRGB → CIE Lab (D65).
List<double> _toLab(Color c) {
  double lin(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  final r = lin(c.r);
  final g = lin(c.g);
  final b = lin(c.b);

  final x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047;
  final y = r * 0.2126 + g * 0.7152 + b * 0.0722;
  final z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883;

  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : (7.787 * t) + (16 / 116);

  final fx = f(x), fy = f(y), fz = f(z);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}
