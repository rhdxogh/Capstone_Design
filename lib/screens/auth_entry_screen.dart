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
            const SizedBox(height: 80),
            // 같은 로고 파일을 검정처럼 보이게(가능하면). 안 먹히면 그냥 그대로 두고 나중에 검정 로고 추가.
            Image.asset(
              'assets/logo_red.png',
              width: 170,
              color: Colors.black,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 60),
            _AuthButton(
              text: 'Log In',
              color: AppColors.brandRed,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _AuthButton(
              text: 'Sign Up',
              color: AppColors.brandRed.withOpacity(0.75),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
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
      width: 220,
      height: 44,
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
