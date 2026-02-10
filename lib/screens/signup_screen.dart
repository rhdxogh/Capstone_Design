import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void dispose() {
    emailCtrl.dispose();
    nickCtrl.dispose();
    userCtrl.dispose();
    pwCtrl.dispose();
    pw2Ctrl.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _signup() async {
    final email = emailCtrl.text.trim();
    final nickname = nickCtrl.text.trim();
    final username = userCtrl.text.trim();
    final pw = pwCtrl.text.trim();
    final pw2 = pw2Ctrl.text.trim();

    if (email.isEmpty || nickname.isEmpty || username.isEmpty || pw.isEmpty || pw2.isEmpty) {
      _toast('필수 항목을 모두 입력해 주세요.');
      return;
    }

    if (pw.length < 6) {
      _toast('비밀번호는 6자리 이상이어야 해요.');
      return;
    }

    if (pw != pw2) {
      _toast('비밀번호가 서로 달라요.');
      return;
    }

    setState(() => loading = true);

    try {
      // 1) Firebase Auth 계정 생성
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pw,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception('회원가입 후 사용자 정보가 없어요.');
      }

      // 2) Firestore에 기본 유저 문서 생성/업데이트
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'email': email,
          'nickname': nickname,
          'username': username,
          'teamId': null, // 팀 선택 전이니까 null
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3) 팀 선택 화면으로 이동
      // 팀 선택 완료 후 teamId를 저장하고 싶으면 TeamSelectScreen에서 선택 완료 시 pop으로 teamId를 돌려주게 만들면 됨.
      // (지금은 기존 네 코드 흐름 유지: TeamSelectScreen으로 이동)
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TeamSelectScreen(uid: user.uid),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = '회원가입에 실패했어요.';
      switch (e.code) {
        case 'email-already-in-use':
          msg = '이미 사용 중인 이메일이에요.';
          break;
        case 'invalid-email':
          msg = '이메일 형식이 올바르지 않아요.';
          break;
        case 'weak-password':
          msg = '비밀번호가 너무 약해요. (6자리 이상 권장)';
          break;
        case 'operation-not-allowed':
          msg = '이메일/비밀번호 로그인이 비활성화되어 있어요. (Firebase 콘솔에서 활성화 필요)';
          break;
      }
      _toast(msg);
    } catch (e) {
      _toast('오류: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
              const SizedBox(height: 6),
              Image.asset(
                'assets/logo_black_font.png',
                width: 140,
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
                  icon: Icon(pwHidden ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              const SizedBox(height: 14),
              _field(
                label: '비밀번호 확인*',
                controller: pw2Ctrl,
                obscure: pw2Hidden,
                suffix: IconButton(
                  onPressed: () => setState(() => pw2Hidden = !pw2Hidden),
                  icon: Icon(pw2Hidden ? Icons.visibility_off : Icons.visibility),
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
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
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

