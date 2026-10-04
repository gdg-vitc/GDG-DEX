import 'package:flutter/material.dart';

/// Pixel-perfect vector implementation of the official Google Developer Groups (GDG) brackets logo (< >).
class GdgLogo extends StatelessWidget {
  final double size;

  const GdgLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final width = size * 1.35;
    final height = size;

    return CustomPaint(
      size: Size(width, height),
      painter: _GdgLogoPainter(),
    );
  }
}

class _GdgLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokeWidth = h * 0.17;

    // Paints for the 4 Google colors
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC04)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Left Bracket <
    final leftArmX = w * 0.38;
    final leftTipX = w * 0.10;
    final topY = h * 0.18;
    final midY = h * 0.50;
    final bottomY = h * 0.82;

    // Red upper arm of <
    canvas.drawLine(
      Offset(leftArmX, topY),
      Offset(leftTipX, midY),
      redPaint,
    );

    // Yellow lower arm of <
    canvas.drawLine(
      Offset(leftTipX, midY),
      Offset(leftArmX, bottomY),
      yellowPaint,
    );

    // Right Bracket >
    final rightArmX = w * 0.62;
    final rightTipX = w * 0.90;

    // Blue upper arm of >
    canvas.drawLine(
      Offset(rightArmX, topY),
      Offset(rightTipX, midY),
      bluePaint,
    );

    // Green lower arm of >
    canvas.drawLine(
      Offset(rightTipX, midY),
      Offset(rightArmX, bottomY),
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
