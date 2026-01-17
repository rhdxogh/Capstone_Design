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
      HomeTab(uid: widget.uid, team: team), // team 객체를 직접 넘김
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
      appBar: AppBar(
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
          if (idx == 0)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              ),
            ),
        ],
      ),
      body: pages[idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (v) => setState(() => idx = v),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: teamColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
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
    );
  }
}
