import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../team_theme.dart'; // ✅ 이미 있는 테마 파일 활용

class StatisticsDetailScreen extends StatelessWidget {
  final String uid;
  final String teamId;
  final List<Map<String, dynamic>> records;

  const StatisticsDetailScreen({
    super.key,
    required this.uid,
    required this.teamId,
    required this.records,
  });

  // 🏟️ 각 구단별 홈 구장 매핑
  static const Map<String, List<String>> teamHomeStadiums = {
    'doosan': ['잠실'],
    'lg': ['잠실'],
    'ssg': ['문학', '인천'],
    'kiwoom': ['고척'],
    'kt': ['수원'],
    'kia': ['광주'],
    'samsung': ['대구'],
    'lotte': ['사직', '부산'],
    'nc': ['창원'],
    'hanwha': ['대전'],
  };

  // ✅ [수정] teamThemes를 활용해 로고 경로 찾기
  String _getLogoPathFromTheme(String teamName) {
    try {
      // teamThemes 값들 중 nameKo가 일치하는 팀을 찾아서 logoPath 반환
      final theme = teamThemes.values.firstWhere((t) => t.nameKo == teamName);
      return theme.logoPath;
    } catch (e) {
      // 못 찾으면 기본값 (KBO 로고 등, 여기선 빈 문자열이나 기본 아이콘 처리)
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 테마 색상 (상단 앱바용)
    final currentTeamColor = teamThemes[teamId]?.primary ?? Colors.black;
    // 승리 강조 색상
    const Color winColor = Color(0xFFC62828);

    int totalWins = 0, totalDraws = 0, totalLosses = 0;
    int homeWins = 0, homeTotal = 0;
    int awayWins = 0, awayTotal = 0;

    // 상대팀별 통계 집계
    Map<String, Map<String, int>> opponentStats = {};

    for (var rec in records) {
      // 데이터 추출
      final result = rec['result'];
      final stadium = rec['stadium'] ?? '';
      final opponent = rec['opponent'] ?? '기타';

      // ✅ 기록 당시의 응원팀 ID (없으면 현재 팀 ID)
      final String recordTeamId = rec['myTeamId'] ?? teamId;
      final List<String> recordHomeStadiums =
          teamHomeStadiums[recordTeamId] ?? [];

      if (result == null) continue; // 예정 경기 제외

      // 1. 전체 승무패
      if (result == '승')
        totalWins++;
      else if (result == '무')
        totalDraws++;
      else if (result == '패')
        totalLosses++;

      // 2. 홈/원정 구분 (기록 당시 팀의 홈구장 기준)
      bool isHomeGame = recordHomeStadiums.any((h) => stadium.contains(h));

      if (isHomeGame) {
        homeTotal++;
        if (result == '승') homeWins++;
      } else {
        awayTotal++;
        if (result == '승') awayWins++;
      }

      // 3. 상대 전적 집계
      if (!opponentStats.containsKey(opponent)) {
        opponentStats[opponent] = {'win': 0, 'draw': 0, 'loss': 0, 'total': 0};
      }
      opponentStats[opponent]!['total'] =
          opponentStats[opponent]!['total']! + 1;

      if (result == '승')
        opponentStats[opponent]!['win'] = opponentStats[opponent]!['win']! + 1;
      else if (result == '무')
        opponentStats[opponent]!['draw'] =
            opponentStats[opponent]!['draw']! + 1;
      else if (result == '패')
        opponentStats[opponent]!['loss'] =
            opponentStats[opponent]!['loss']! + 1;
    }

    double homeRate = homeTotal > 0 ? (homeWins / homeTotal * 100) : 0.0;
    double awayRate = awayTotal > 0 ? (awayWins / awayTotal * 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('직관 상세 분석'),
        backgroundColor: currentTeamColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전체 승률 카드
            _buildSummaryCard(totalWins, totalDraws, totalLosses, winColor),

            const SizedBox(height: 20),
            const Text(
              '🏟️ 홈 vs 원정 승률',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _buildHomeAwayBar('홈 직관', homeRate, homeWins, homeTotal, winColor),
            const SizedBox(height: 10),
            _buildHomeAwayBar(
              '원정 직관',
              awayRate,
              awayWins,
              awayTotal,
              Colors.grey,
            ),

            const SizedBox(height: 24),
            const Text(
              '🆚 상대 팀별 전적',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _buildOpponentList(opponentStats, winColor),
          ],
        ),
      ),
    );
  }

  // 요약 카드
  Widget _buildSummaryCard(int w, int d, int l, Color winColor) {
    int total = w + d + l;
    double rate = total > 0 ? (w / (w + l) * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 25,
                sections: total == 0
                    ? [
                        PieChartSectionData(
                          color: Colors.grey[200],
                          value: 1,
                          showTitle: false,
                          radius: 10,
                        ),
                      ]
                    : [
                        if (w > 0)
                          PieChartSectionData(
                            color: winColor,
                            value: w.toDouble(),
                            showTitle: false,
                            radius: 10,
                          ),
                        if (d > 0)
                          PieChartSectionData(
                            color: Colors.green,
                            value: d.toDouble(),
                            showTitle: false,
                            radius: 10,
                          ),
                        if (l > 0)
                          PieChartSectionData(
                            color: Colors.blue,
                            value: l.toDouble(),
                            showTitle: false,
                            radius: 10,
                          ),
                      ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '총 $total전 $w승 $d무 $l패',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 홈/원정 바
  Widget _buildHomeAwayBar(
    String label,
    double rate,
    int wins,
    int total,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '$wins승 / $total경기 (${rate.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: total > 0 ? color : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? rate / 100 : 0,
              backgroundColor: Colors.grey[100],
              color: color,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // 상대 전적 리스트
  Widget _buildOpponentList(
    Map<String, Map<String, int>> stats,
    Color winColor,
  ) {
    if (stats.isEmpty) return const Center(child: Text('아직 상대 전적 데이터가 없습니다.'));

    var sortedKeys = stats.keys.toList()
      ..sort((a, b) => stats[b]!['total']!.compareTo(stats[a]!['total']!));

    return Column(
      children: sortedKeys.map((teamName) {
        final data = stats[teamName]!;
        int w = data['win']!;
        int d = data['draw']!;
        int l = data['loss']!;
        int t = data['total']!;
        double winRate = (w + l) > 0 ? (w / (w + l) * 100) : 0.0;

        // ✅ [수정] teamThemes에서 로고 경로 가져오기
        String logoPath = _getLogoPathFromTheme(teamName);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // 로고 이미지 표시
              SizedBox(
                width: 40,
                height: 40,
                child: logoPath.isNotEmpty
                    ? Image.asset(
                        logoPath,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackLogo(teamName),
                      )
                    : _buildFallbackLogo(teamName),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$t전 $w승 $d무 $l패',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${winRate.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: winRate >= 50 ? winColor : Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 로고가 없을 때 보여줄 기본 위젯
  Widget _buildFallbackLogo(String teamName) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Text(
        teamName.isNotEmpty ? teamName.substring(0, 1) : '?',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
