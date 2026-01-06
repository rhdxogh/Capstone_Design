import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ 상단 여백 (iOS 감성 포인트)
            const SizedBox(height: 220),

            // ✅ 로고 크게
            Image.asset(
              'assets/logo_black_font.png',
              width: 250,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 80),

            // ✅ 버튼 영역을 Center로
            Center(
              child: Column(
                children: [
                  _AuthButton(
                    text: 'Log In',
                    color: AppColors.brandRed,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AuthButton(
                    text: 'Sign Up',
                    color: AppColors.brandRed.withOpacity(0.75),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignUpScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _AuthButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260, // ✅ 버튼 폭 증가
      height: 52, // ✅ 버튼 높이 증가
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}





