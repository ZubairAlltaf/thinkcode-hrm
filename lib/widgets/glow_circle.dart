import 'package:flutter/material.dart';
class GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const GlowCircle({
    super.key,
    required this.size,
    this.color = Colors.white,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}
