import 'dart:async';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'auth_entry_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const SplashScreen({super.key, this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthEntryScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 900), goNext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandRed,
      body: Center(
        child: GestureDetector(
          onTap: goNext,
          child: Image.asset('assets/logo_red.png', width: 180),
        ),
      ),
    );
  }
}
