import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:thinkcode/screens/signup_screen.dart';
import 'package:thinkcode/widgets/glow_circle.dart';
import 'package:thinkcode/widgets/think_code_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>SignUpScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const Positioned(
            top: -40,
            left: -40,
            child: GlowCircle(size: 150),
          ),
          const Positioned(
            bottom: -40,
            right: -40,
            child: GlowCircle(size: 120),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                ThinkCodeLogo(),
                SizedBox(height: 20),
                CircularProgressIndicator(color: Colors.white70),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
