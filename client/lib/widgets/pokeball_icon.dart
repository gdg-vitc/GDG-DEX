import 'package:flutter/material.dart';

/// A custom vector Pokéball icon that scales cleanly at any size.
class PokeballIcon extends StatelessWidget {
  final double size;

  const PokeballIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _PokeballPainter(),
      ),
    );
  }
}

class _PokeballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clipPath);

    // Top half: Red
    final redPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 2), redPaint);

    // Bottom half: White
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, h / 2, w, h / 2), whitePaint);

    canvas.restore();

    // Outer border ring: Dark slate
    final darkRing = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08;
    canvas.drawCircle(center, radius - (w * 0.04), darkRing);

    // Center dividing line: Dark slate
    final linePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: w, height: h * 0.10),
      linePaint,
    );

    // Center button outer circle: Dark slate
    final centerOuter = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.32, centerOuter);

    // Center button inner circle: White
    final centerInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.20, centerInner);

    // Center button highlight ring
    final centerRing = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;
    canvas.drawCircle(center, radius * 0.12, centerRing);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
