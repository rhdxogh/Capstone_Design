import 'package:flutter/material.dart';
import '../team_theme.dart';
import 'tabs/home_tab.dart';
import 'tabs/stadium_tab.dart';
import 'tabs/weather_tab.dart';
import 'tabs/my_tab.dart';
import 'calendar_screen.dart';

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

  void changeTeam(String newTeamId) {
    setState(() => currentTeamId = newTeamId);
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
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
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
