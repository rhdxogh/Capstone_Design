import 'package:flutter/material.dart';
import '../team_theme.dart';
import 'tabs/home_tab.dart';
import 'tabs/stadium_tab.dart';
import 'tabs/weather_tab.dart';
import 'tabs/my_tab.dart';
import 'calendar_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainShell extends StatefulWidget {
  final String uid;
  final String teamId;
  const MainShell({super.key, required this.uid, required this.teamId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int idx = 0;
  late String currentTeamId;

  @override
  void initState() {
    super.initState();
    currentTeamId = widget.teamId;
  }

  void changeTeam(String newTeamId) async {
    // 1. 먼저 UI를 즉시 업데이트해서 사용자에게 보여줌
    setState(() => currentTeamId = newTeamId);

    try {
      // 2. Firestore의 'users' 컬렉션에서 해당 유저(uid)의 teamId를 업데이트
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'teamId': newTeamId,
        'updatedAt': FieldValue.serverTimestamp(), // 업데이트 시간 기록 (선택사항)
      }, SetOptions(merge: true)); // 기존 데이터는 유지하고 teamId만 덮어쓰기

      print('업데이트 완료: $newTeamId');
    } catch (e) {
      // 에러 발생 시 처리
      print('업데이트 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('팀 변경사항을 저장하지 못했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = teamThemes[currentTeamId] ?? teamThemes['ssg']!;
    final teamColor = team.primary;

    final pages = [
      HomeTab(uid: widget.uid, team: team),
      StadiumTab(teamColor: teamColor),
      WeatherTab(teamColor: teamColor),
      MyTab(
        uid: widget.uid,
        teamColor: teamColor,
        currentTeamId: currentTeamId,
        onTeamChanged: changeTeam,
      ),
    ];

    return Scaffold(
      appBar: idx == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: teamColor,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              title: Text(
                team.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CalendarScreen(currentTeamId: currentTeamId),
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: pages[idx],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // 아주 미세한 그림자로 섹션 분리
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (v) => setState(() => idx = v),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white, // ✅ 핑크빛 제거하고 완전 흰색으로
          selectedItemColor: teamColor,
          unselectedItemColor: Colors.grey.shade400,
          elevation: 0, // 상단 Container의 그림자를 사용하므로 기본 elevation은 0
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.stadium_outlined),
              label: '구장',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny_outlined),
              label: '날씨',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }
}
