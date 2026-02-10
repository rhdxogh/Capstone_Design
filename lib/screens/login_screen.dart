import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_colors.dart';
import 'signup_screen.dart';
import 'team_select_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final pwCtrl = TextEditingController();

  bool remember = true; // FirebaseAuth는 기본적으로 로그인 유지됨
  bool pwHidden = true;
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    pwCtrl.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // ✅ uid로 Firestore에서 teamId 조회
  Future<String?> _getTeamId(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    final teamId = data?['teamId'];
    if (teamId is String && teamId.isNotEmpty) return teamId;
    return null;
  }

  // ✅ uid 문서에 teamId 저장(merge)
  Future<void> _saveTeamId(String uid, String teamId) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'teamId': teamId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _login() async {
    final email = emailCtrl.text.trim();
    final password = pwCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _toast('이메일/비밀번호를 입력해 주세요.');
      return;
    }

    setState(() => loading = true);

    try {
      // 1) 로그인
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        _toast('로그인에 실패했어요. (user=null)');
        return;
      }

      final uid = user.uid;

      // 2) 기존 teamId 있는지 확인
      final teamId = await _getTeamId(uid);
      if (!mounted) return;

      if (teamId != null) {
        // ✅ teamId 있으면 바로 메인
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainShell(
              uid: uid,
              teamId: teamId,
            ),
          ),
              (_) => false,
        );
        return;
      }

      // 3) teamId 없으면 팀 선택 화면으로 이동해서 선택값을 pop으로 받기
      final selectedTeamId = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (_) => TeamSelectScreen(
            uid: uid,
            returnSelectedTeamId: true, // 너가 만든 옵션
          ),
        ),
      );

      if (!mounted) return;

      if (selectedTeamId == null || selectedTeamId.isEmpty) {
        _toast('팀 선택이 취소되었어요.');
        return;
      }

      // 4) 선택한 teamId 저장 후 메인 이동
      await _saveTeamId(uid, selectedTeamId);
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(
            uid: uid,
            teamId: selectedTeamId,
          ),
        ),
            (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = '로그인에 실패했어요.';
      switch (e.code) {
        case 'invalid-email':
          msg = '이메일 형식이 올바르지 않아요.';
          break;
        case 'user-not-found':
          msg = '존재하지 않는 계정이에요.';
          break;
        case 'wrong-password':
          msg = '비밀번호가 틀렸어요.';
          break;
        case 'invalid-credential':
          msg = '이메일 또는 비밀번호가 올바르지 않아요.';
          break;
        case 'user-disabled':
          msg = '비활성화된 계정이에요.';
          break;
        case 'too-many-requests':
          msg = '시도가 너무 많아요. 잠시 후 다시 해주세요.';
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
              Image.asset('assets/logo_black_font.png', width: 140),
              const SizedBox(height: 24),
              const Text('로그인', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),

              _field(label: '이메일*', controller: emailCtrl),
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
                    child: Text('Forgot the password ?', style: TextStyle(color: AppColors.brandRed)),
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
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
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
                      style: TextStyle(color: AppColors.brandRed, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}




