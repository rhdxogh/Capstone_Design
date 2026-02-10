import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'auth_entry_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    // ✅ 스플래시 보여줄 시간 (원하는 값으로 조절)
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const  AuthEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          '직관메이트',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

