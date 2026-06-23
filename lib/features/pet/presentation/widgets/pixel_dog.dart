import 'package:flutter/material.dart';
import '../../domain/pet.dart';

/// 그리드에 픽셀(정사각형)을 찍어 픽셀아트 느낌을 내는 헬퍼.
class _Px {
  _Px(this.canvas, this.unit);
  final Canvas canvas;
  final double unit;

  void rect(int x, int y, int w, int h, Color color) {
    final p = Paint()
      ..color = color
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
      p,
    );
  }

  void dot(int x, int y, Color color) => rect(x, y, 1, 1, color);
}

/// 강아지 얼굴 (온보딩 커스터마이즈/정보입력 화면용). 16x16 그리드 기준.
class PixelDogFace extends StatelessWidget {
  const PixelDogFace({
    super.key,
    required this.furColor,
    this.eyeStyle = EyeStyle.round,
    this.noseStyle = NoseStyle.triangle,
    this.mouthStyle = MouthStyle.smile,
    this.size = 120,
  });

  final Color furColor;
  final EyeStyle eyeStyle;
  final NoseStyle noseStyle;
  final MouthStyle mouthStyle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DogFacePainter(
        fur: furColor,
        eye: eyeStyle,
        nose: noseStyle,
        mouth: mouthStyle,
      ),
    );
  }
}

class _DogFacePainter extends CustomPainter {
  _DogFacePainter({
    required this.fur,
    required this.eye,
    required this.nose,
    required this.mouth,
  });

  final Color fur;
  final EyeStyle eye;
  final NoseStyle nose;
  final MouthStyle mouth;

  static const grid = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / grid;
    final px = _Px(canvas, unit);

    // 색 톤: 흰 털이면 윤곽선만 보이도록 약간 어두운 라인 사용.
    final isLight = fur.computeLuminance() > 0.75;
    final outline = isLight ? const Color(0xFFE3D9C8) : _darken(fur, 0.25);
    final cheek = const Color(0xFFF4B6B6);
    final dark = const Color(0xFF3A3030);

    // 귀 (양옆 복슬 블롭)
    px.rect(1, 5, 3, 5, fur);
    px.rect(12, 5, 3, 5, fur);
    px.rect(1, 5, 3, 5, fur);

    // 얼굴 본체 (둥근 사각형 형태)
    px.rect(4, 3, 8, 2, fur);
    px.rect(3, 5, 10, 7, fur);
    px.rect(4, 12, 8, 1, fur);

    // 윤곽 살짝 (위/아래)
    px.rect(4, 2, 8, 1, outline);
    px.rect(4, 13, 8, 1, outline);
    px.dot(2, 6, outline);
    px.dot(13, 6, outline);

    // 볼터치
    px.rect(3, 9, 2, 2, cheek);
    px.rect(11, 9, 2, 2, cheek);

    // 눈
    _eyes(px, dark);

    // 코
    _nose(px, dark);

    // 입
    _mouth(px, dark);
  }

  void _eyes(_Px px, Color dark) {
    switch (eye) {
      case EyeStyle.round:
        px.rect(5, 6, 2, 2, dark);
        px.rect(9, 6, 2, 2, dark);
        px.dot(5, 6, Colors.white); // 하이라이트
        px.dot(9, 6, Colors.white);
      case EyeStyle.sparkle:
        px.rect(5, 6, 2, 2, dark);
        px.rect(9, 6, 2, 2, dark);
        px.dot(6, 6, Colors.white);
        px.dot(10, 6, Colors.white);
        px.dot(4, 5, const Color(0xFFFFE08A));
        px.dot(11, 5, const Color(0xFFFFE08A));
      case EyeStyle.sleepy:
        px.rect(5, 7, 2, 1, dark);
        px.rect(9, 7, 2, 1, dark);
    }
  }

  void _nose(_Px px, Color dark) {
    switch (nose) {
      case NoseStyle.triangle:
        px.rect(7, 8, 2, 1, dark);
        px.dot(7, 9, dark);
      case NoseStyle.round:
        px.rect(7, 8, 2, 2, dark);
      case NoseStyle.heart:
        px.dot(7, 8, const Color(0xFFE86C8E));
        px.dot(8, 8, const Color(0xFFE86C8E));
        px.dot(7, 9, const Color(0xFFE86C8E));
    }
  }

  void _mouth(_Px px, Color dark) {
    switch (mouth) {
      case MouthStyle.smile:
        px.dot(6, 10, dark);
        px.dot(7, 11, dark);
        px.dot(8, 11, dark);
        px.dot(9, 10, dark);
      case MouthStyle.tongue:
        px.rect(7, 10, 2, 1, dark);
        px.rect(7, 11, 2, 1, const Color(0xFFE86C8E)); // 혀
      case MouthStyle.grin:
        px.rect(6, 10, 4, 1, dark);
        px.rect(6, 11, 4, 1, const Color(0xFFB85A5A)); // 입 안
        px.rect(7, 11, 2, 1, const Color(0xFFE86C8E));
    }
  }

  static Color _darken(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amount).clamp(0, 1)).toColor();
  }

  @override
  bool shouldRepaint(covariant _DogFacePainter old) =>
      old.fur != fur ||
      old.eye != eye ||
      old.nose != nose ||
      old.mouth != mouth;
}

/// 홈에서 좌우로 걸어다니는 전신 강아지 (측면 뷰). [walkPhase]로 다리 애니메이션.
class PixelDogWalker extends StatelessWidget {
  const PixelDogWalker({
    super.key,
    required this.furColor,
    required this.walkPhase,
    this.facingRight = true,
    this.size = 96,
  });

  final Color furColor;
  final int walkPhase; // 0 또는 1
  final bool facingRight;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dog = CustomPaint(
      size: Size.square(size),
      painter: _DogWalkerPainter(fur: furColor, phase: walkPhase),
    );
    return facingRight
        ? dog
        : Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.1415926),
            child: dog,
          );
  }
}

class _DogWalkerPainter extends CustomPainter {
  _DogWalkerPainter({required this.fur, required this.phase});
  final Color fur;
  final int phase;

  static const grid = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / grid;
    final px = _Px(canvas, unit);
    final isLight = fur.computeLuminance() > 0.75;
    final outline = isLight ? const Color(0xFFE3D9C8) : _DogFacePainter._darken(fur, 0.25);
    final dark = const Color(0xFF3A3030);

    // 몸통
    px.rect(3, 7, 8, 4, fur);
    px.rect(4, 6, 6, 1, fur);
    // 머리 (오른쪽)
    px.rect(9, 4, 5, 5, fur);
    px.rect(13, 6, 1, 2, fur); // 주둥이
    // 귀
    px.rect(9, 3, 2, 2, outline);
    // 꼬리 (살랑)
    if (phase == 0) {
      px.rect(2, 5, 1, 2, fur);
      px.dot(1, 4, fur);
    } else {
      px.rect(2, 6, 1, 2, fur);
      px.dot(1, 7, fur);
    }
    // 눈/코
    px.dot(12, 6, dark);
    px.dot(14, 7, dark); // 코

    // 다리 (2프레임 교차)
    if (phase == 0) {
      px.rect(4, 11, 1, 2, fur); // 앞-왼
      px.rect(6, 11, 1, 1, fur); // 뒤로
      px.rect(8, 11, 1, 2, fur);
      px.rect(10, 11, 1, 1, fur);
    } else {
      px.rect(4, 11, 1, 1, fur);
      px.rect(6, 11, 1, 2, fur);
      px.rect(8, 11, 1, 1, fur);
      px.rect(10, 11, 1, 2, fur);
    }
  }

  @override
  bool shouldRepaint(covariant _DogWalkerPainter old) =>
      old.fur != fur || old.phase != phase;
}
