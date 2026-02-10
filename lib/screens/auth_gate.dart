import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_entry_screen.dart';
import 'main_shell.dart';
import 'team_select_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> _getTeamId(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    final teamId = data?['teamId'];

    if (teamId is String && teamId.isNotEmpty) return teamId;
    return null;
  }

  Future<void> _saveTeamId(String uid, String teamId) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'teamId': teamId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // 1) 로그인 상태 확인 중
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2) 로그인 안 됨
        final user = authSnap.data;
        if (user == null) {
          return const AuthEntryScreen();
        }

        // 3) 로그인 됨 -> teamId 확인
        return FutureBuilder<String?>(
          future: _getTeamId(user.uid),
          builder: (context, teamSnap) {
            if (teamSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final teamId = teamSnap.data;

            // teamId 있으면 바로 메인
            if (teamId != null) {
              return MainShell(uid: user.uid, teamId: teamId);
            }

            // teamId 없으면: 선택 화면을 push로 띄우고 결과를 받아 저장 후 메인으로
            return _PickTeamThenGo(
              uid: user.uid,
              saveTeamId: _saveTeamId,
            );
          },
        );
      },
    );
  }
}

class _PickTeamThenGo extends StatefulWidget {
  final String uid;
  final Future<void> Function(String uid, String teamId) saveTeamId;

  const _PickTeamThenGo({
    required this.uid,
    required this.saveTeamId,
  });

  @override
  State<_PickTeamThenGo> createState() => _PickTeamThenGoState();
}

class _PickTeamThenGoState extends State<_PickTeamThenGo> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // build 중 Navigator 호출하면 꼬일 수 있어서 postFrame으로 안전하게 실행
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPickerOnce());
  }

  Future<void> _openPickerOnce() async {
    if (_opened) return;
    _opened = true;

    final selectedTeamId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => TeamSelectScreen(
          uid: widget.uid,
          returnSelectedTeamId: true,
        ),
      ),
    );

    if (!mounted) return;

    if (selectedTeamId == null) {
      // 선택 안 하고 뒤로 간 경우
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구단을 선택해야 메인으로 이동할 수 있어요.')),
      );
      _opened = false;
      return;
    }

    await widget.saveTeamId(widget.uid, selectedTeamId);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainShell(uid: widget.uid, teamId: selectedTeamId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
