import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_colors.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'team_select_screen.dart';
import 'main_shell.dart';
import 'nickname_setup_screen.dart';

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

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc(String uid) async {
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  Future<String?> _getTeamId(String uid) async {
    final doc = await _getUserDoc(uid);
    if (!doc.exists) return null;
    final teamId = doc.data()?['teamId'];
    if (teamId is String && teamId.isNotEmpty) return teamId;
    return null;
  }

  Future<String?> _getNickname(String uid) async {
    final doc = await _getUserDoc(uid);
    if (!doc.exists) return null;
    final nickname = doc.data()?['nickname'];
    if (nickname is String && nickname.isNotEmpty) return nickname;
    return null;
  }

  Future<void> _saveTeamId(String uid, String teamId) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'teamId': teamId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveDefaultProfile(String uid, User user) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ✅ 로그인 성공 후 공통 처리 (닉네임/프사 설정 -> 팀 선택 -> 메인)
  Future<void> _goAfterLogin(User user) async {
    final uid = user.uid;
    await _saveDefaultProfile(uid, user);

    String? nickname = await _getNickname(uid);
    if (!mounted) return;

    if (nickname == null || nickname.isEmpty) {
      final savedNickname = await Navigator.push<String?>(
        context,
        MaterialPageRoute(builder: (_) => NicknameSetupScreen(uid: uid)),
      );
      if (!mounted) return;
      if (savedNickname == null || savedNickname.isEmpty) {
        _toast('닉네임 설정이 취소되었어요.');
        return;
      }
      nickname = savedNickname;
    }

    final teamId = await _getTeamId(uid);
    if (!mounted) return;

    if (teamId != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(uid: uid, teamId: teamId),
        ),
        (_) => false,
      );
      return;
    }

    final selectedTeamId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => TeamSelectScreen(uid: uid, returnSelectedTeamId: true),
      ),
    );

    if (!mounted) return;
    if (selectedTeamId == null || selectedTeamId.isEmpty) {
      _toast('팀 선택이 취소되었어요.');
      return;
    }

    await _saveTeamId(uid, selectedTeamId);
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainShell(uid: uid, teamId: selectedTeamId),
      ),
      (_) => false,
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
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        _toast('로그인에 실패했어요. (user=null)');
        return;
      }
      await _goAfterLogin(user);
    } on FirebaseAuthException catch (e) {
      String msg = '로그인에 실패했어요.';
      if (e.code == 'invalid-email')
        msg = '이메일 형식이 올바르지 않아요.';
      else if (e.code == 'user-not-found')
        msg = '존재하지 않는 계정이에요.';
      else if (e.code == 'wrong-password')
        msg = '비밀번호가 틀렸어요.';
      else if (e.code == 'invalid-credential')
        msg = '이메일 또는 비밀번호가 올바르지 않아요.';
      _toast(msg);
    } catch (e) {
      _toast('오류: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => loading = true);
    try {
      final cred = await AuthService.signInWithGoogle();
      final user = cred.user;
      if (user == null) {
        _toast('구글 로그인에 실패했어요.');
        return;
      }
      await _goAfterLogin(user);
    } catch (e) {
      _toast('구글 로그인 실패: $e');
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
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Log In'),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Google로 로그인'),
                  onPressed: loading ? null : _googleLogin,
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
