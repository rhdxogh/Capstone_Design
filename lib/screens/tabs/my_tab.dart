import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../team_theme.dart';
import '../statistics_detail_screen.dart';
import '../../screens/my_reviews_screen.dart';
import '../../screens/my_records_list_screen.dart';
import '../../screens/my_posts_screen.dart';
import '../../screens/settings_screen.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class MyTab extends StatelessWidget {
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
    final teamName = teamThemes[currentTeamId]?.nameKo ?? '-';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError)
          return const Center(child: Text('유저 정보 로드 실패'));
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final String nickname = userData?['nickname'] ?? '닉네임';

        final String? profileImageBase64 = userData?['profileImageBase64'];

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('jikgwan_records')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return const Center(child: Text('데이터 로드 실패'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              int wins = 0;
              int draws = 0;
              int losses = 0;
              List<Map<String, dynamic>> rawRecords = [];

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                // 내 팀 아이디가 다르면 패스
                if (data['myTeamId'] != currentTeamId) continue;

                // 🌟 핵심 추가: 상대팀 이름에 'vs'가 있거나 '타팀경기'인 경우 통계 카드에서 완전 제외!
                final String opponent = data['opponent'] ?? '';
                if (opponent.contains('vs') || opponent == '타팀경기') continue;

                rawRecords.add(data);

                final result = data['result'];
                if (result == '승')
                  wins++;
                else if (result == '무')
                  draws++;
                else if (result == '패')
                  losses++;
              }

              double winRate = 0.0;
              if ((wins + losses) > 0) {
                winRate = (wins / (wins + losses)) * 100;
              }

              // 🌟 헤더를 스크롤 바깥으로 빼서 고정시킵니다.
              return Column(
                children: [
                  _buildHeader(
                    nickname,
                    teamName,
                    profileImageBase64,
                    currentTeamId,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildWinRateCard(
                            context,
                            wins,
                            draws,
                            losses,
                            winRate,
                            rawRecords,
                          ),
                          const SizedBox(height: 20),
                          _buildMenuSection(context),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // 🌟 파라미터로 teamId를 받아옵니다 (이건 아까 하신 것과 동일해요)
  Widget _buildHeader(
    String nickname,
    String teamName,
    String? base64Image,
    String teamId,
  ) {
    // 🌟 핵심 수정: 팀 테마 로고가 아닌, 직접 지정해주신 마스코트 경로 사용!
    final String mascotPath = teamId.isNotEmpty
        ? 'assets/mascot_img/$teamId.png'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(color: teamColor),
      child: Row(
        children: [
          // 📸 프로필 이미지 영역 (커스텀 프사 or 구단 마스코트)
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            // 1순위: 사용자가 설정한 프사 (Base64)
            // 2순위: 마스코트 이미지 (mascotPath)
            backgroundImage: base64Image != null && base64Image.isNotEmpty
                ? MemoryImage(base64Decode(base64Image)) as ImageProvider
                : (mascotPath.isNotEmpty
                      ? AssetImage(mascotPath) as ImageProvider
                      : null),

            // 둘 다 에러나거나 없을 때 최후의 보루로 띄워줄 사람 아이콘
            child:
                (base64Image == null || base64Image.isEmpty) &&
                    mascotPath.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nickname 님,',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '응원팀 : $teamName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinRateCard(
    BuildContext context,
    int w,
    int d,
    int l,
    double rate,
    List<Map<String, dynamic>> rawRecords,
  ) {
    bool isEmpty = (w + d + l) == 0;
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatisticsDetailScreen(
                        uid: uid,
                        teamId: currentTeamId,
                        records: rawRecords,
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: Colors.grey[700],
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '나의 직관 승률은?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (!isEmpty)
                      const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 40,
                              sections: isEmpty
                                  ? [
                                      PieChartSectionData(
                                        color: Colors.grey[200],
                                        value: 1,
                                        radius: 15,
                                        showTitle: false,
                                      ),
                                    ]
                                  : [
                                      if (w > 0)
                                        PieChartSectionData(
                                          color: const Color(0xFFC62828),
                                          value: w.toDouble(),
                                          radius: 15,
                                          showTitle: false,
                                        ),
                                      if (d > 0)
                                        PieChartSectionData(
                                          color: const Color(0xFF4CAF50),
                                          value: d.toDouble(),
                                          radius: 15,
                                          showTitle: false,
                                        ),
                                      if (l > 0)
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
                              isEmpty ? '-' : '${rate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('승리 ($w)', const Color(0xFFC62828)),
                        const SizedBox(height: 8),
                        _buildLegendItem('무승부 ($d)', const Color(0xFF4CAF50)),
                        const SizedBox(height: 8),
                        _buildLegendItem('패배 ($l)', const Color(0xFF2196F3)),
                      ],
                    ),
                  ],
                ),
                if (!isEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    '👆 카드를 눌러 상세 직관 승률 확인하기',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        ),
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
          _buildMenuTile('내가 작성한 후기 관리', Icons.rate_review_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MyReviewsScreen(uid: uid, themeColor: teamColor),
              ),
            );
          }),
          const Divider(height: 1, indent: 20, endIndent: 20),

          // 🌟 새롭게 추가된 '내가 쓴 게시글 관리' 메뉴
          _buildMenuTile('내가 작성한 게시글 관리', Icons.article_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyPostsScreen(uid: uid, themeColor: teamColor),
              ),
            );
          }),
          const Divider(height: 1, indent: 20, endIndent: 20),

          _buildMenuTile('직관 기록 모아보기', Icons.format_list_bulleted, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MyRecordsListScreen(uid: uid, themeColor: teamColor),
              ),
            );
          }),
          const Divider(height: 1, indent: 20, endIndent: 20),

          _buildMenuTile('내 정보 수정', Icons.settings_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  uid: uid,
                  teamColor: teamColor,
                  currentTeamId: currentTeamId,
                  onTeamChanged: onTeamChanged,
                ),
              ),
            );
          }, isLast: true),
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
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
