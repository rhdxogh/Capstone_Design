import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';

import '../app_colors.dart';
import 'login_screen.dart';
import 'nickname_setup_screen.dart';
import 'team_select_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final pw2Ctrl = TextEditingController();

  bool pwHidden = true;
  bool pw2Hidden = true;
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
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
    final pw = pwCtrl.text.trim();
    final pw2 = pw2Ctrl.text.trim();

    if (email.isEmpty || pw.isEmpty || pw2.isEmpty) {
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
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pw,
      );
      final user = cred.user;
      if (user == null) throw Exception('회원가입 후 사용자 정보가 없어요.');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'teamId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      // 1) 닉네임 & 프사 설정 화면으로 이동
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NicknameSetupScreen(uid: user.uid)),
      );

      if (!mounted) return;

      // 2) 팀 선택 화면으로 이동하면서 밑에 깔린 이전 화면(로그인 첫 화면) 싹 지우기!
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => TeamSelectScreen(uid: user.uid)),
        (route) => false, // 이 코드가 이전 기록을 전부 날려줍니다.
      );
    } on FirebaseAuthException catch (e) {
      String msg = '회원가입에 실패했어요.';
      if (e.code == 'email-already-in-use')
        msg = '이미 사용 중인 이메일이에요.';
      else if (e.code == 'invalid-email')
        msg = '이메일 형식이 올바르지 않아요.';
      else if (e.code == 'weak-password')
        msg = '비밀번호가 너무 약해요. (6자리 이상 권장)';
      _toast(msg);
    } catch (e) {
      _toast('오류: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
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

  // 구글 연동 후 닉네임/팀 선택 혹은 메인 화면으로 보내주는 공통 로직
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
              const SizedBox(height: 18),
              const Text(
                '회원가입',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),

              _field(label: '이메일 입력*', controller: emailCtrl),
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
                  icon: const Icon(Icons.login), // 로그인 화면과 동일한 아이콘 사용
                  label: const Text('Google로 시작하기'), // 텍스트 변경
                  onPressed: loading
                      ? null
                      : _googleLogin, // 회원가입 화면의 구글 로그인 함수 연결
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
