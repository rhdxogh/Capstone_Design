import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../team_theme.dart';

class LineupScreen extends StatefulWidget {
  final Map<String, dynamic> game;
  final Color themeColor;

  const LineupScreen({super.key, required this.game, required this.themeColor});

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  bool isHomeTab = true;

  // 색상 정의 (상단 매치 카드와 스코어보드 R 공용)
  static const Color strongRed = Color(0xFFCC0000);

  final Map<String, String> koToEnPos = {
    '투수': 'SP',
    '포수': 'C',
    '1루수': '1B',
    '2루수': '2B',
    '3루수': '3B',
    '유격수': 'SS',
    '좌익수': 'LF',
    '중견수': 'CF',
    '우익수': 'RF',
    '지명타자': 'DH',
  };

  final Map<String, Offset> fieldCoords = {
    'C': const Offset(0.38, 0.92),
    'SP': const Offset(0.38, 0.62),
    'CF': const Offset(0.38, 0.12), // 0.08 -> 0.12 (조금 내림)
    // 외야 대칭 (안쪽으로 모음)
    'LF': const Offset(0.04, 0.28), // 0.02 -> 0.04 (오른쪽으로)
    'RF': const Offset(0.68, 0.28), // 0.74 -> 0.68 (왼쪽으로 확!)

    'SS': const Offset(0.18, 0.46),
    '2B': const Offset(0.54, 0.46),
    '3B': const Offset(0.06, 0.72),
    '1B': const Offset(0.66, 0.72),

    // 지명타자 (숫자 잘림 방지: 왼쪽으로 확 땡김)
    'DH': const Offset(0.65, 0.85), // 0.80 -> 0.65 (확 땡김!)
  };

  // --- ID 및 로고 헬퍼 ---
  String _getKboGameId() {
    final parts = widget.game['date'].toString().split('.');
    final y = parts[0];
    final m = parts[1].padLeft(2, '0');
    final d = parts[2].padLeft(2, '0');
    String getCode(String t) {
      if (t.contains('SSG')) return 'SK';
      if (t.contains('삼성')) return 'SS';
      if (t.contains('두산')) return 'OB';
      if (t.contains('KIA')) return 'HT';
      if (t.contains('LG')) return 'LG';
      if (t.contains('NC')) return 'NC';
      if (t.contains('롯데')) return 'LT';
      if (t.contains('키움')) return 'WO';
      if (t.contains('한화')) return 'HH';
      if (t.contains('KT')) return 'KT';
      return t;
    }

    return "$y$m$d${getCode(widget.game['away'])}${getCode(widget.game['home'])}0";
  }

  String _getLineupDocId() {
    final parts = widget.game['date'].toString().split('.');
    final y = parts[0];
    final m = parts[1].padLeft(2, '0');
    final d = parts[2].padLeft(2, '0');
    return "${y}${m}${d}_${widget.game['away']}_${widget.game['home']}";
  }

  String _getLogo(String teamName) {
    String logo = 'assets/team_logo_img/ssg.png';
    for (var v in teamThemes.values) {
      if (v.nameKo == teamName ||
          v.id.toUpperCase() == teamName.toUpperCase()) {
        logo = v.logoPath;
        break;
      }
    }
    return logo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          "${widget.game['date']} 경기 정보",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('kbo_scoreboards')
            .doc(_getKboGameId())
            .snapshots(),
        builder: (context, scoreSnapshot) {
          final scoreData = scoreSnapshot.data?.data() as Map<String, dynamic>?;
          final scoreboard = scoreData?['scoreboard'] as List<dynamic>?;

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _buildTopMatchCard(scoreData),
              if (scoreboard != null) _buildScoreBoardCard(scoreboard),
              _buildLineupSection(),
            ],
          );
        },
      ),
    );
  }

  // 1. 상단 매치 카드
  Widget _buildTopMatchCard(Map<String, dynamic>? scoreData) {
    final scoreboard = scoreData?['scoreboard'] as List<dynamic>?;
    int aR = 0, hR = 0;
    if (scoreboard != null && scoreboard.length >= 2) {
      aR = int.tryParse(scoreboard[0]['R'].toString()) ?? 0;
      hR = int.tryParse(scoreboard[1]['R'].toString()) ?? 0;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _teamInfo(widget.game['away']),
          Column(
            children: [
              Text(
                widget.game['stadium'],
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "$aR",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: aR > hR
                          ? strongRed
                          : (aR < hR ? Colors.grey : Colors.black87),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'vs',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    "$hR",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: hR > aR
                          ? strongRed
                          : (hR < aR ? Colors.grey : Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _teamInfo(widget.game['home']),
        ],
      ),
    );
  }

  Widget _teamInfo(String name) {
    return Column(
      children: [
        Image.asset(_getLogo(name), width: 55, height: 55),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }

  // 2. 스코어보드 (11회까지 표시 및 R 승패 색상 적용)
  Widget _buildScoreBoardCard(List<dynamic> scoreboard) {
    final awayInnings = scoreboard[0]['innings'] as List<dynamic>;
    final homeInnings = scoreboard[1]['innings'] as List<dynamic>;

    // 12회 제외, 최대 11회까지만 표시
    int displayInnings = 11;
    if (awayInnings.length < displayInnings)
      displayInnings = awayInnings.length;

    int aR = int.tryParse(scoreboard[0]['R'].toString()) ?? 0;
    int hR = int.tryParse(scoreboard[1]['R'].toString()) ?? 0;

    // R 부분 색상 결정
    Color awayRColor = aR > hR
        ? strongRed
        : (aR < hR ? Colors.grey : Colors.black87);
    Color homeRColor = hR > aR
        ? strongRed
        : (hR < aR ? Colors.grey : Colors.black87);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          horizontalMargin: 0,
          headingRowHeight: 35,
          dataRowMinHeight: 35,
          columns: [
            const DataColumn(
              label: SizedBox(
                width: 60,
                child: Text('팀', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            for (int i = 1; i <= displayInnings; i++)
              DataColumn(
                label: Text('$i', style: const TextStyle(fontSize: 12)),
              ),
            const DataColumn(
              label: Text('R', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const DataColumn(
              label: Text('H', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const DataColumn(
              label: Text('E', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const DataColumn(
              label: Text('B', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: [
            _buildScoreRow(
              widget.game['away'],
              awayInnings.sublist(0, displayInnings),
              scoreboard[0],
              awayRColor,
            ),
            _buildScoreRow(
              widget.game['home'],
              homeInnings.sublist(0, displayInnings),
              scoreboard[1],
              homeRColor,
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildScoreRow(
    String team,
    List<dynamic> innings,
    dynamic data,
    Color rColor,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            team,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        for (var score in innings)
          DataCell(
            Text(score.toString(), style: const TextStyle(fontSize: 13)),
          ),
        DataCell(
          Text(
            data['R'].toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: rColor,
              fontSize: 14,
            ),
          ),
        ), // 득점 색상 적용
        DataCell(
          Text(data['H'].toString(), style: const TextStyle(fontSize: 13)),
        ),
        DataCell(
          Text(data['E'].toString(), style: const TextStyle(fontSize: 13)),
        ),
        DataCell(
          Text(data['B'].toString(), style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  // 3. 라인업 섹션
  Widget _buildLineupSection() {
    final String docId = _getLineupDocId();

    // 🔥 [핵심 추가] 경기 날짜가 '오늘(또는 미래)'인지 판별하는 로직
    final parts = widget.game['date'].toString().split('.');
    final gameYear = int.tryParse(parts[0]) ?? DateTime.now().year;
    final gameMonth = int.tryParse(parts[1]) ?? DateTime.now().month;
    final gameDay = int.tryParse(parts[2]) ?? DateTime.now().day;

    final gameDate = DateTime(gameYear, gameMonth, gameDay);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // 경기 날짜가 오늘이거나 미래일 때만 true
    final bool showWarningBanner =
        gameDate.isAtSameMomentAs(today) || gameDate.isAfter(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '선발 라인업',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ToggleButtons(
                isSelected: [isHomeTab, !isHomeTab],
                onPressed: (index) => setState(() => isHomeTab = index == 0),
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: widget.themeColor,
                constraints: const BoxConstraints(minHeight: 32, minWidth: 60),
                children: [
                  const Text(
                    'Home',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Away',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),

        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('kbo_games')
              .doc(docId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("경기 정보 업데이트 전입니다."));
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final lineupData = data['lineup'] as Map<String, dynamic>;
            final List<dynamic> players = isHomeTab
                ? lineupData['away']
                : lineupData['home'];

            return Column(
              children: [
                // 🌟 과거 경기에서는 배너가 아예 안 보이고, 오늘 경기만 배너가 뜹니다!
                if (showWarningBanner)
                  Container(
                    margin: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFF9800),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '공식 라인업 발표 전입니다.\n최근 기록을 바탕으로 구성되어 실제 명단과 다를 수 있습니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: AssetImage('assets/lineup_img/background.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          for (int i = 0; i < players.length; i++) ...[
                            () {
                              final player = players[i];
                              String rawPos = player['pos'].toString().trim();
                              String posEn =
                                  koToEnPos[rawPos] ?? rawPos.toUpperCase();
                              if (posEn == 'P' || posEn == 'RP') posEn = 'SP';
                              if (fieldCoords.containsKey(posEn)) {
                                return _buildPlayerBadge(
                                  constraints,
                                  posEn,
                                  player['name'],
                                  (i + 1).toString(),
                                );
                              }
                              return const SizedBox.shrink();
                            }(),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildPlayerList(players),
              ],
            );
          },
        ),
      ],
    );
  }

  // 💊 이름 자간 넓히고 전체적으로 오른쪽 밀기 버전
  Widget _buildPlayerBadge(
    BoxConstraints constraints,
    String pos,
    String name,
    String order,
  ) {
    final offset = fieldCoords[pos]!;
    final String fileName = pos.toLowerCase();

    return Positioned(
      left: constraints.maxWidth * offset.dx,
      top: constraints.maxHeight * offset.dy,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // 1. 배경 배지 이미지
          Image.asset(
            'assets/lineup_img/$fileName.png',
            height: 22,
            fit: BoxFit.contain,
          ),

          // 2. 이름 배치 (오른쪽으로 살짝 이동 + 자간 확보)
          Padding(
            padding: const EdgeInsets.only(left: 24), // 20 -> 24 (오른쪽으로 미세 이동)
            child: SizedBox(
              width: 58,
              height: 22,
              child: Center(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.0, // -1.0 -> 0.0 (글자 간격 시원하게 변경)
                  ),
                ),
              ),
            ),
          ),

          // 3. 타순 숫자 (함께 오른쪽으로 이동)
          Padding(
            padding: const EdgeInsets.only(
              left: 81,
            ), // 80 -> 83 (원 중앙에 맞게 미세 이동)
            child: SizedBox(
              width: 18,
              height: 22,
              child: Center(
                child: Text(
                  order,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List<dynamic> players) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: players.length,
          separatorBuilder: (context, index) => const SizedBox.shrink(),
          itemBuilder: (context, index) {
            final p = players[index];
            final bool isEven = index % 2 == 0;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              color: isEven ? Colors.white : const Color(0xFFF2F4F7),
              child: Row(
                children: [
                  // 1. 타순 (왼쪽 고정 너비를 75로 확대)
                  SizedBox(
                    width: 75,
                    child: Text(
                      '${index + 1}번',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),

                  // 2. 선수 이름 (정중앙 정렬)
                  Expanded(
                    child: Text(
                      p['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D2939),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  // 3. 포지션 (오른쪽 고정 너비를 75로 확대하여 '지명타자' 한 줄 유지)
                  SizedBox(
                    width: 75,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ), // 좌우 패딩 살짝 조정
                        decoration: BoxDecoration(
                          color: isEven
                              ? const Color(0xFFF2F4F7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p['pos'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1, // 한 줄 고정
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
