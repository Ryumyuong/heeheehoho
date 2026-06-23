import 'package:flutter/material.dart';

/// 벽 + 창문(하늘/구름/잔디) + 커튼. [offset]만큼 가로로 스크롤(패럴랙스 느린 레이어).
class WallPainter extends CustomPainter {
  WallPainter(this.offset);
  final double offset;

  static const period = 360.0;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;

    // 벽
    p.color = const Color(0xFFF1E2C6);
    canvas.drawRect(Offset.zero & size, p);

    // 반복되는 창문
    final startK = ((offset) / period).floor() - 1;
    for (int k = startK; k < startK + 4; k++) {
      final wx = k * period - offset + 70;
      _window(canvas, p, wx, 60, 170, 150);
    }
  }

  void _window(Canvas c, Paint p, double x, double y, double w, double h) {
    // 하늘
    p.color = const Color(0xFF8FD3E8);
    c.drawRect(Rect.fromLTWH(x, y, w, h), p);
    // 잔디 언덕
    p.color = const Color(0xFF7FB069);
    c.drawRect(Rect.fromLTWH(x, y + h - 40, w, 40), p);
    p.color = const Color(0xFF6FA05C);
    c.drawRect(Rect.fromLTWH(x + 20, y + h - 54, 70, 20), p);
    // 구름
    p.color = Colors.white;
    c.drawRect(Rect.fromLTWH(x + w * 0.45, y + 24, 42, 12), p);
    c.drawRect(Rect.fromLTWH(x + w * 0.52, y + 16, 26, 10), p);

    // 창틀 (나무)
    final frame = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF9C6B43)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    c.drawRect(Rect.fromLTWH(x, y, w, h), frame);
    // 십자 창살
    c.drawRect(Rect.fromLTWH(x + w / 2 - 4, y, 8, h), p..color = const Color(0xFF9C6B43));
    c.drawRect(Rect.fromLTWH(x, y + h / 2 - 4, w, 8), p);

    // 커튼 봉
    p.color = const Color(0xFF7A5230);
    c.drawRect(Rect.fromLTWH(x - 16, y - 14, w + 32, 8), p);
    // 커튼 (오른쪽)
    p.color = const Color(0xFFF0E2C4);
    c.drawRect(Rect.fromLTWH(x + w - 30, y - 6, 40, h + 6), p);
    p.color = const Color(0xFFE2D0A8);
    for (double cy = y; cy < y + h; cy += 16) {
      c.drawRect(Rect.fromLTWH(x + w - 26, cy, 4, 16), p);
    }
  }

  @override
  bool shouldRepaint(covariant WallPainter old) => old.offset != offset;
}

/// 벽돌/타일 바닥. [offset]만큼 스크롤(패럴랙스 빠른 레이어).
class FloorPainter extends CustomPainter {
  FloorPainter(this.offset);
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;

    // 바닥 베이스
    p.color = const Color(0xFFE7C9A0);
    canvas.drawRect(Offset.zero & size, p);

    // 상단 트림(걸레받이)
    p.color = const Color(0xFFD9B589);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 6), p);

    // 벽돌 줄 (엇갈리게)
    const bw = 80.0, bh = 26.0;
    p.color = const Color(0xFFD9B98E);
    final line = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFFCBA877)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    int row = 0;
    for (double y = 8; y < size.height; y += bh) {
      final stagger = (row.isEven) ? 0.0 : bw / 2;
      final startX = -((offset + stagger) % bw) - bw;
      for (double x = startX; x < size.width + bw; x += bw) {
        canvas.drawRect(Rect.fromLTWH(x, y, bw, bh), p);
        canvas.drawRect(Rect.fromLTWH(x, y, bw, bh), line);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant FloorPainter old) => old.offset != offset;
}
