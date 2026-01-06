import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'signup_screen.dart';
import 'team_select_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  bool remember = true;
  bool pwHidden = true;
  bool loading = false;

  Future<void> _login() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TeamSelectScreen(uid: 'mock')),
    );
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/logo_black_font.png',
                width: 140,
                // color: Colors.black,
                // colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(height: 24),
              const Text(
                '로그인',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              _field(label: '이메일*', controller: emailCtrl),
              const SizedBox(height: 14),
              _field(
                label: '비밀번호*',
                controller: pwCtrl,
                obscure: pwHidden,
                suffix: IconButton(
                  onPressed: () => setState(() => pwHidden = !pwHidden),
                  icon: Icon(
                    pwHidden ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: remember,
                    activeColor: AppColors.brandRed,
                    onChanged: (v) => setState(() => remember = v ?? true),
                  ),
                  const Text('Remember me'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _toast('비밀번호 재설정은 나중에 연결할 수 있어요.'),
                    child: Text(
                      'Forgot the password ?',
                      style: TextStyle(color: AppColors.brandRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: loading ? null : _login,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Log In'),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("don't have an account ? "),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.brandRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
