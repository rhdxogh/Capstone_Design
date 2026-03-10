import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();

  String? verificationId;
  bool codeSent = false;
  bool loading = false;

  @override
  void dispose() {
    phoneCtrl.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => loading = true);

    await AuthService.verifyPhoneNumber(
      phoneNumber: phoneCtrl.text.trim(),
      onCodeSent: (id) {
        if (!mounted) return;
        setState(() {
          verificationId = id;
          codeSent = true;
          loading = false;
        });
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
  }

  Future<void> _verifyCode() async {
    if (verificationId == null) return;

    setState(() => loading = true);

    try {
      await AuthService.signInWithSmsCode(
        verificationId: verificationId!,
        smsCode: codeCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증코드 확인 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전화번호 로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '전화번호',
                hintText: '+821012345678',
              ),
            ),
            const SizedBox(height: 12),
            if (codeSent)
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '인증코드',
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : (codeSent ? _verifyCode : _sendCode),
              child: Text(
                loading ? '처리 중...' : (codeSent ? '인증코드 확인' : '인증코드 받기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}