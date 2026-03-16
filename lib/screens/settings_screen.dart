import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'auth_entry_screen.dart';
import 'team_select_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String uid;
  final Color teamColor;
  final String currentTeamId;
  final ValueChanged<String> onTeamChanged;

  const SettingsScreen({
    super.key,
    required this.uid,
    required this.teamColor,
    required this.currentTeamId,
    required this.onTeamChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          '설정',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        children: [
          _buildSectionTitle('계정 설정'),
          _buildSettingsBox([
            // 1. 닉네임 변경
            _buildListTile(context, '닉네임 변경', Icons.badge_outlined, () {
              _showNicknameChangeDialog(context);
            }),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // 2. 프로필 이미지 설정 (갤러리에서 선택)
            _buildListTile(context, '프로필 이미지 설정', Icons.image_outlined, () {
              _pickAndSaveProfileImage(context);
            }),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // 🌟 3. 기본 프로필로 변경 (새로 추가됨!)
            _buildListTile(context, '기본 프로필로 변경', Icons.face, () {
              _resetToDefaultProfile(context);
            }),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // 4. 응원하는 팀 변경하기
            _buildListTile(context, '응원하는 팀 변경하기', Icons.swap_horiz, () async {
              final selected = await Navigator.push<String?>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TeamSelectScreen(uid: uid, returnSelectedTeamId: true),
                ),
              );
              if (selected != null) {
                onTeamChanged(selected);
                Navigator.pop(context); // 팀 변경 후 마이페이지로 돌아가기
              }
            }, isLast: true),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('기타'),
          _buildSettingsBox([
            _buildListTile(
              context,
              '로그아웃',
              Icons.logout,
              () => _handleLogout(context),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildListTile(
              context,
              '회원탈퇴',
              Icons.person_remove_outlined,
              () => _handleDeleteAccount(context),
              isDestructive: true,
              isLast: true,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsBox(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
    bool isLast = false,
  }) {
    final color = isDestructive ? Colors.red[400] : Colors.black87;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: isLast ? Radius.zero : const Radius.circular(16),
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
      ),
    );
  }

  // ==========================================
  // 🔥 닉네임 변경 로직
  // ==========================================
  void _showNicknameChangeDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '닉네임 변경',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '새 닉네임을 입력하세요',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: teamColor, width: 2),
            ),
          ),
          maxLength: 10,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'nickname': newName});
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('닉네임이 성공적으로 변경되었습니다!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
                }
              }
            },
            child: Text(
              '변경',
              style: TextStyle(color: teamColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🔥 사진 갤러리 픽업 & Base64 저장 로직
  // ==========================================
  Future<void> _pickAndSaveProfileImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30, // 화질 압축 (중요)
        maxWidth: 200,
        maxHeight: 200,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final String base64String = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageBase64': base64String,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 이미지가 성공적으로 변경되었습니다!')),
        );
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이미지 변경 실패: $e')));
    }
  }

  // ==========================================
  // 🔥 기본 프로필(마스코트)로 되돌리기 로직 (새로 추가!)
  // ==========================================
  Future<void> _resetToDefaultProfile(BuildContext context) async {
    try {
      // 파이어베이스에서 프사(profileImageBase64) 필드를 삭제해버립니다.
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageBase64': FieldValue.delete(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('기본 마스코트 프로필로 변경되었습니다!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('변경 실패: $e')));
      }
    }
  }

  // ==========================================
  // 기타: 로그아웃 & 탈퇴 로직
  // ==========================================
  Future<void> _handleLogout(BuildContext context) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('로그아웃하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('로그아웃', style: TextStyle(color: teamColor)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthEntryScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              '회원 탈퇴',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('정말로 탈퇴하시겠어요?\n모든 직관 기록이 삭제되며 복구할 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  '탈퇴',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final records = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('jikgwan_records')
              .get();
          for (var doc in records.docs) {
            await doc.reference.delete();
          }
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
          await user.delete();

          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthEntryScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('탈퇴 오류: $e')));
      }
    }
  }
}
