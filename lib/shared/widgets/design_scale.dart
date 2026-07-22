import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

/// true면 화면 좌상단에 실측 크기(w×h, scale, 캔버스)를 띄운다(디버그용).
/// 원인 파악 끝나면 false로 되돌린다. 릴리즈에서는 항상 숨김.
const bool _kShowSizeDebug = false;

/// 앱 전체를 "디자인 시안 폭"의 캔버스로 그린 뒤, 화면 폭에 맞춰 통째로 확대·축소한다.
///
/// 폰트만 [TextScaler]로 키우면 글자는 커지는데 아이콘·이미지·여백은 그대로라
/// 시안의 비율이 깨진다. 여기서는 캔버스 자체를 배율로 늘리므로 **폰트·아이콘·
/// 이미지·여백이 한꺼번에 같은 비율로** 움직인다.
///
/// ## 폭에 따른 동작
/// - **[scaleUpTo](600px) 이하**: 시안 폭([designWidth]) 캔버스를 화면 폭에 꽉 채운다.
///   배율 = 화면폭 / 412 → 폰트·이미지가 폭에 비례해 커지고 작아진다.
/// - **600px 초과**: 배율을 더 키우지 않는다. 그래서 글자·버튼·강아지의 크기가
///   600px일 때와 같게 유지되고, 넓어진 만큼 화면이 **좌우로만 늘어난다**.
/// - **[mobileMaxWidth](990px) 초과**: 캔버스를 990 상당 폭에 고정하고 가운데 정렬.
///   양옆 여백은 [background]로 채운다.
class DesignScale extends StatelessWidget {
  const DesignScale({
    super.key,
    required this.child,
    this.designWidth = 412,
    // scaleUpTo == designWidth 이면 최대 배율 1.0 → minScale 1.0과 합쳐 scale은
    // 항상 1.0. 어떤 화면에서도 콘텐츠를 확대·축소하지 않고 1:1로 그리고,
    // 레이아웃이 실제 화면 폭에 맞춰 반응형으로 배치된다.
    this.scaleUpTo = 412,
    // 990px 이하는 그 폭 그대로 채운다. 991px 이상(진짜 태블릿)만 990 컬럼으로
    // 가운데 정렬하고 양옆에 여백을 둔다.
    this.mobileMaxWidth = 990,
    this.minScale = 1.0,
    this.background = const Color(0xFFE7E2DA),
  });

  final Widget child;

  /// 디자인 시안 기준 폭(px). 이 폭에서 각 화면의 크기 값이 시안과 1:1로 맞는다.
  final double designWidth;

  /// 폰트·이미지가 커지는 상한 폭. 이 폭에서의 배율이 앱이 쓰는 최대 배율이 된다.
  final double scaleUpTo;

  /// 모바일로 취급하는 최대 폭. 넘어가면 캔버스를 이 폭에 고정하고 가운데 정렬.
  final double mobileMaxWidth;

  final double minScale;

  /// 넓은 화면에서 캔버스 양옆을 채울 색.
  final Color background;

  /// 시안 폭(412) 기준 값을 지금 캔버스 폭에 비례해 환산한다.
  ///
  /// 600px 이하에서는 캔버스가 항상 412라 값이 그대로 나오고(28 → 28),
  /// 그보다 넓어지면 캔버스가 넓어진 만큼 값도 함께 커진다.
  /// 화면이 넓어질 때 여백만 고정돼 콘텐츠가 가장자리에 붙는 걸 막는다.
  static double scaled(BuildContext context, double atDesignWidth) =>
      MediaQuery.sizeOf(context).width * atDesignWidth / 412;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        if (w == 0 || h == 0) return child;

        // 배율은 600px에서의 값이 상한. 그 이상 넓어져도 더 키우지 않아
        // 글자·이미지 크기가 600px일 때와 같게 유지된다.
        final maxScale = scaleUpTo / designWidth;
        final scale = (w / designWidth).clamp(minScale, maxScale);

        // 배율을 되돌린 논리 크기. 600px까지는 정확히 designWidth이고,
        // 그보다 넓으면 캔버스가 좌우로 넓어진다.
        final maxCanvas = mobileMaxWidth / maxScale;
        final canvasWidth = (w / scale).clamp(0.0, maxCanvas);
        final canvasHeight = h / scale;

        final mq = MediaQuery.of(context);

        final scaled = ColoredBox(
          color: background,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: MediaQuery(
                  data: mq.copyWith(
                    size: Size(canvasWidth, canvasHeight),
                    // 캔버스가 이미 배율을 담당하므로 글자만 또 키우지 않는다.
                    textScaler: TextScaler.noScaling,
                    padding: mq.padding / scale,
                    viewPadding: mq.viewPadding / scale,
                    viewInsets: mq.viewInsets / scale,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );

        if (kReleaseMode || !_kShowSizeDebug) return scaled;
        // 디버그: 실측 크기를 좌상단에 겹쳐 띄운다.
        return Stack(
          children: [
            scaled,
            Positioned(
              left: 0,
              top: mq.padding.top,
              child: IgnorePointer(
                child: Container(
                  color: const Color(0xCC000000),
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'screen ${w.toStringAsFixed(0)}×${h.toStringAsFixed(0)}\n'
                    'dpr ${mq.devicePixelRatio.toStringAsFixed(2)}  '
                    'scale ${scale.toStringAsFixed(3)}\n'
                    'canvas ${canvasWidth.toStringAsFixed(0)}×'
                    '${canvasHeight.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF00FF66),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
