import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.68,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.4,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  children: [
                    const _DrawerHeader(),
                    const SizedBox(height: 30),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _DrawerItem(
                            title: 'Dashboard',
                            icon: Icons.dashboard,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/home');
                            },
                          ),
                          _DrawerItem(
                            title: 'Settings',
                            icon: Icons.settings,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/home');
                            },
                          ),
                          _DrawerItem(
                            title: 'Logout',
                            icon: Icons.logout,
                            onTap: () async {
                              Navigator.pop(context);
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);

                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _DrawerHeader extends StatefulWidget {
  const _DrawerHeader();

  @override
  State<_DrawerHeader> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<_DrawerHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: GlowRingPainter(_controller.value),
                  size: const Size(100, 100),
                ),
              ),
              const CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(
                  'https://images.pexels.com/photos/3201580/pexels-photo-3201580.jpeg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Muhammad Zubair',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
            ),
          ),
          const Text(
            'zubairalltafdev@gmail.com',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              shadows: [Shadow(blurRadius: 3, color: Colors.black26)],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.white10,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlowRingPainter extends CustomPainter {
  final double progress;

  GlowRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius);

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * pi,
      transform: GradientRotation(2 * pi * progress),
      colors: const [
        Colors.pinkAccent,
        Colors.lightBlueAccent,
        Colors.limeAccent,
        Colors.pinkAccent,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset(radius, radius), radius - 3, paint);
  }

  @override
  bool shouldRepaint(covariant GlowRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
