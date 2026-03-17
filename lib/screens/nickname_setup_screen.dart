import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _base64Image;

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // 📸 이미지 갤러리에서 선택 & Base64 변환
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30, // 화질 압축
        maxWidth: 200,
        maxHeight: 200,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      _toast('사진을 불러오는 중 오류가 발생했습니다.');
    }
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
      Map<String, dynamic> dataToSave = {
        'nickname': nickname,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 🌟 이미지를 골랐다면 데이터에 함께 추가
      if (_base64Image != null) {
        dataToSave['profileImageBase64'] = _base64Image;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set(dataToSave, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context, nickname);
    } catch (e) {
      _toast('저장 실패: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '프로필 설정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // 키보드 올라올 때 대비
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // 📸 프로필 사진 선택 UI
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _base64Image != null
                          ? MemoryImage(base64Decode(_base64Image!))
                          : null,
                      child: _base64Image == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey.shade400,
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16), // 간격 살짝 띄우기
              // 🌟 새로 추가된 친절한 안내 문구!
              Text(
                '사진을 선택하지 않으면\n구단 마스코트 사진의 기본 프로필로 설정돼요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '사용할 닉네임을 입력해 주세요',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '후기와 커뮤니티에서 표시될 이름이에요.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      : const Text(
                          '저장하고 계속하기',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
