import 'dart:math';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class ParticleBackground extends StatelessWidget {
  const ParticleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2027), // dark navy
                Color(0xFF134E5E), // dark emerald
                Color(0xFF203A43), // slightly teal
                Color(0xFF2C5364), // soft cyan
                Color(0xFF71B280), // mint green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),


        CustomAnimationBuilder<double>(
          control: Control.loop,
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 60),
          builder: (context, value, child) {
            return CustomPaint(
              painter: ParticlePainter(value),
              child: const SizedBox.expand(),
            );
          },
        ),
      ],
    );
  }
}

class Particle {
  Offset position;
  double radius;
  Color color;
  double speed;

  Particle(this.position, this.radius, this.color, this.speed);
}

class ParticlePainter extends CustomPainter {
  final double progress;
  final List<Particle> particles = [];
  final Random random = Random();

  ParticlePainter(this.progress) {
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final radius = random.nextDouble() * 2.5 + 1.5;

      final colors = [
        Colors.white.withOpacity(random.nextDouble() * 0.03 + 0.4),
        Colors.blueAccent.withOpacity(random.nextDouble() * 0.02 + 0.3),
        Colors.purpleAccent.withOpacity(random.nextDouble() * 0.02 + 0.3),
        Colors.tealAccent.withOpacity(random.nextDouble() * 0.02 + 0.3),
      ];

      final color = colors[random.nextInt(colors.length)];
      final speed = random.nextDouble() * 0.1 + 0.02;

      particles.add(Particle(Offset(x, y), radius, color, speed));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (final p in particles) {
      final dy = (p.position.dy + progress * p.speed) % 100.0;
      final offset = Offset(p.position.dx * size.width, dy * size.height);
      paint.color = p.color;
      canvas.drawCircle(offset, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
