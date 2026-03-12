import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_colors.dart';

class NicknameSetupScreen extends StatefulWidget {
  final String uid;
  final String? initialNickname;

  const NicknameSetupScreen({
    super.key,
    required this.uid,
    this.initialNickname,
  });

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  final controller = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    controller.text = widget.initialNickname ?? '';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m)),
    );
  }

  Future<void> _save() async {
    final nickname = controller.text.trim();

    if (nickname.isEmpty) {
      _toast('닉네임을 입력해 주세요.');
      return;
    }

    if (nickname.length < 2) {
      _toast('닉네임은 2자 이상 입력해 주세요.');
      return;
    }

    if (nickname.length > 12) {
      _toast('닉네임은 12자 이하로 입력해 주세요.');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set(
        {
          'nickname': nickname,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.pop(context, nickname);
    } catch (e) {
      _toast('닉네임 저장 실패: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('닉네임 설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                '사용할 닉네임을 입력해 주세요',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '마이페이지와 후기에서 표시될 이름이에요.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: controller,
                maxLength: 12,
                decoration: InputDecoration(
                  hintText: '예: 열혈야구팬',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: loading ? null : _save,
                  child: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('저장하고 계속하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}