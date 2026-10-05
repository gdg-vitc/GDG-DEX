import 'package:flutter/material.dart';

/// Official Google Developer Groups (GDG) logo widget using the chapter emblem image.
class GdgLogo extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;

  const GdgLogo({
    super.key,
    this.size = 48,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(size * 0.16),
      child: Image.asset(
        'assets/images/gdg_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.code_rounded,
            size: size * 0.7,
            color: const Color(0xFF4285F4),
          );
        },
      ),
    );
  }
}
