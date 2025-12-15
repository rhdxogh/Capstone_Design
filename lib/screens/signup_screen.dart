import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'login_screen.dart';
import 'team_select_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailCtrl = TextEditingController();
  final nickCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final pw2Ctrl = TextEditingController();

  bool pwHidden = true;
  bool pw2Hidden = true;
  bool loading = false;

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _signup() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TeamSelectScreen(uid: 'mock')),
    );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/logo_red.png',
                width: 140,
                color: Colors.black,
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(height: 18),
              const Text(
                '회원가입',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),

              _field(label: '이메일 입력*', controller: emailCtrl),
              const SizedBox(height: 14),
              _field(label: '닉네임 입력*', controller: nickCtrl),
              const SizedBox(height: 14),
              _field(label: '아이디 입력*', controller: userCtrl),
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
              const SizedBox(height: 14),
              _field(
                label: '비밀번호 확인*',
                controller: pw2Ctrl,
                obscure: pw2Hidden,
                suffix: IconButton(
                  onPressed: () => setState(() => pw2Hidden = !pw2Hidden),
                  icon: Icon(
                    pw2Hidden ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),

              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: loading ? null : _signup,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Sign Up'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account ? '),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: AppColors.brandRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
