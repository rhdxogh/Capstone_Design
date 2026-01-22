import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // 차트 패키지 필요
import '../../team_theme.dart';
import '../team_select_screen.dart';

class MyTab extends StatelessWidget {
  // ✅ main_shell.dart에서 넘겨주는 매개변수들 정의
  final String uid;
  final Color teamColor;
  final String currentTeamId;
  final ValueChanged<String> onTeamChanged;

  const MyTab({
    super.key,
    required this.uid,
    required this.teamColor,
    required this.currentTeamId,
    required this.onTeamChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 팀의 이름을 가져옴
    final teamName = teamThemes[currentTeamId]?.nameKo ?? '-';

    // ✅ 임시 데이터 (나중에 캘린더 데이터와 연동)
    const int wins = 5;
    const int draws = 1;
    const int losses = 6;
    const double winRate = 45.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 상단 프로필 헤더 (전달받은 teamColor 사용)
            _buildHeader(teamName),

            const SizedBox(height: 20),

            // 2. 직관 승률 통계 카드 (전달받은 teamColor 사용)
            _buildWinRateCard(wins, draws, losses, winRate),

            const SizedBox(height: 20),

            // 3. 하단 메뉴 리스트 (응원팀 변경 기능 포함)
            _buildMenuSection(context),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 상단 헤더 섹션
  Widget _buildHeader(String teamName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        color: teamColor, // ✅ main_shell에서 받은 색상 적용
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '열혈야구팬 님,',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '응원팀 : $teamName',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHeaderInfo(Icons.edit_note, '작성 후기', '3개'),
              const SizedBox(width: 20),
              _buildHeaderInfo(Icons.stadium_outlined, '관람 경기', '12경기'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
        const SizedBox(width: 6),
        Text(
          '$label : ',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // 승률 통계 카드
  Widget _buildWinRateCard(int w, int d, int l, double rate) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined, color: Colors.grey[700], size: 22),
              const SizedBox(width: 8),
              const Text(
                '직관 승률은?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 도넛 차트
              SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: teamColor,
                            value: w.toDouble(),
                            radius: 15,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFF4CAF50),
                            value: d.toDouble(),
                            radius: 15,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFF2196F3),
                            value: l.toDouble(),
                            radius: 15,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Text(
                        '${rate.toInt()}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 범례
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem('승리', teamColor),
                  const SizedBox(height: 8),
                  _buildLegendItem('무승부', const Color(0xFF4CAF50)),
                  const SizedBox(height: 8),
                  _buildLegendItem('패', const Color(0xFF2196F3)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
      ],
    );
  }

  // 메뉴 섹션
  Widget _buildMenuSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile('작성한 후기 관리', Icons.rate_review_outlined, () {}),
          const Divider(height: 1, indent: 20, endIndent: 20),
          // ✅ 응원팀 변경 로직 유지
          _buildMenuTile('응원하는 팀 변경하기', Icons.swap_horiz, () async {
            final selected = await Navigator.push<String?>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TeamSelectScreen(uid: uid, returnSelectedTeamId: true),
              ),
            );
            if (selected != null) onTeamChanged(selected);
          }),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildMenuTile('로그아웃', Icons.logout, () {}),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildMenuTile(
            '회원탈퇴',
            Icons.person_remove_outlined,
            () {},
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: title == '회원탈퇴' ? Colors.red[300] : Colors.black87,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: title == '회원탈퇴' ? Colors.red[300] : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
