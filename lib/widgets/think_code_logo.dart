import 'package:flutter/material.dart';

class ThinkCodeLogo extends StatelessWidget {
  const ThinkCodeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [Colors.blueAccent, Colors.cyanAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: const Text(
        'Think Code',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: Colors.white,
          fontFamily: 'RobotoMono',
        ),
      ),
    );
  }
}
