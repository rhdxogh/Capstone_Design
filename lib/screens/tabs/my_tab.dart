import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../team_theme.dart';
import '../team_select_screen.dart';
import '../auth_entry_screen.dart';
import '../statistics_detail_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('jikgwan_records')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('데이터 로드 실패'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          int wins = 0;
          int draws = 0;
          int losses = 0;
          int totalGames = 0;
          int reviewCount = 0;

          List<Map<String, dynamic>> rawRecords = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            // ✅ [핵심] 현재 설정된 팀의 기록만 가져오기 (팀 세탁 방지)
            // myTeamId가 없는 옛날 데이터는... 여기서 안 보이게 됩니다. (깔끔한 새 출발)
            if (data['myTeamId'] != currentTeamId) continue;

            rawRecords.add(data);

            final result = data['result'];
            final title = data['title'] as String?;

            if (result == '승') {
              wins++;
              totalGames++;
            } else if (result == '무') {
              draws++;
              totalGames++;
            } else if (result == '패') {
              losses++;
              totalGames++;
            }

            if (title != null && title.isNotEmpty) {
              reviewCount++;
            }
          }

          double winRate = 0.0;
          if ((wins + losses) > 0) {
            winRate = (wins / (wins + losses)) * 100;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(teamName, totalGames, reviewCount),
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
          );
        },
      ),
    );
  }

  Widget _buildHeader(String teamName, int totalGames, int reviewCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(color: teamColor),
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
              _buildHeaderInfo(Icons.emoji_events, '기록된 직관', '${totalGames}경기'),
              const SizedBox(width: 20),
              _buildHeaderInfo(Icons.edit_note, '작성한 후기', '${reviewCount}개'),
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
                          '직관 승률은?',
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
                    '👆 카드를 눌러 상세 분석 확인하기',
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
          _buildMenuTile('로그아웃', Icons.logout, () async {
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
          }),
          const Divider(height: 1, indent: 20, endIndent: 20),
          // ✅ 회원탈퇴 로직 수정됨
          _buildMenuTile('회원탈퇴', Icons.person_remove_outlined, () async {
            bool confirm =
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text(
                      '회원 탈퇴',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      '정말로 탈퇴하시겠어요? 모든 직관 기록이 삭제되며 복구할 수 없습니다.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          '취소',
                          style: TextStyle(color: Colors.grey),
                        ),
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
                  // 1. 하위 컬렉션(직관 기록) 먼저 모두 삭제
                  final records = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('jikgwan_records')
                      .get();

                  for (var doc in records.docs) {
                    await doc.reference.delete();
                  }

                  // 2. 유저 문서 삭제
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .delete();

                  // 3. 인증 계정 삭제
                  await user.delete();

                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthEntryScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('탈퇴 오류: $e')));
                }
              }
            }
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
    );
  }
}
