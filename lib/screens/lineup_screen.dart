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
    'CF': const Offset(0.38, 0.12),
    'LF': const Offset(0.04, 0.28),
    'RF': const Offset(0.68, 0.28),
    'SS': const Offset(0.18, 0.46),
    '2B': const Offset(0.54, 0.46),
    '3B': const Offset(0.06, 0.72),
    '1B': const Offset(0.66, 0.72),
    'DH': const Offset(0.65, 0.85),
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
      if (t.contains('KIA') || t.contains('기아')) return 'HT'; // 기아/KIA 예외처리 추가
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

  // 🔥 [핵심] main_shell 수정 없이 색상과 이름 매칭을 완벽하게 처리하는 함수
  bool _isMyTeamGame() {
    for (var v in teamThemes.values) {
      // 1. 넘어온 테마색과 일치하는 내 구단 찾기
      if (v.primary.value == widget.themeColor.value) {
        String away = widget.game['away'].toString().trim().toUpperCase();
        String home = widget.game['home'].toString().trim().toUpperCase();
        String tId = v.id.toUpperCase(); // 예: 'DOOSAN'
        String tName = v.nameKo.toUpperCase(); // 예: '두산 베어스'

        // 2. 기아 / KIA 한영 혼용 완벽 호환 처리
        if (away == 'KIA') away = '기아';
        if (home == 'KIA') home = '기아';
        if (tId == 'KIA') tId = '기아';

        // 3. '두산' in '두산 베어스' 처럼 포함 관계를 양방향으로 검사
        if (away.contains(tId) ||
            home.contains(tId) ||
            tName.contains(away) ||
            tName.contains(home)) {
          return true; // 내 팀 경기가 확실함!
        }
      }
    }
    return false; // 매칭 안 되면 타구단 경기
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 여기서 내 구단 여부를 판별해 앱바 색상만 결정합니다.
    final bool isMyTeam = _isMyTeamGame();
    final Color appBarBgColor = isMyTeam ? widget.themeColor : Colors.white;
    final Color appBarFgColor = isMyTeam ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      //backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "${widget.game['date']} 경기 정보",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: appBarFgColor, // 텍스트 색상
          ),
        ),
        centerTitle: true,
        backgroundColor: appBarBgColor, // 바탕 색상
        foregroundColor: appBarFgColor, // 뒤로가기 아이콘 색상
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
              _buildLineupSection(isMyTeam), // 토글 버튼 색상을 위해 isMyTeam 전달
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
                      color: aR > hR ? strongRed : Colors.black, // 지는 팀 블랙 통일
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'vs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    "$hR",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: hR > aR ? strongRed : Colors.black, // 지는 팀 블랙 통일
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

    // R 부분 색상 결정 (회색 걷어내고 블랙으로 통일)
    Color awayRColor = aR > hR ? strongRed : Colors.black;
    Color homeRColor = hR > aR ? strongRed : Colors.black;

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
        ),
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
  Widget _buildLineupSection(bool isMyTeam) {
    final String docId = _getLineupDocId();

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
                // 타구단 경기일 때는 버튼 색상도 무난한 진회색으로 맞춰줍니다
                fillColor: isMyTeam ? widget.themeColor : Colors.grey.shade800,
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
          Image.asset(
            'assets/lineup_img/$fileName.png',
            height: 22,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24),
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
                    letterSpacing: 0.0,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 81),
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
        color: Colors.white,
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
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 20,
            endIndent: 20,
          ),
          itemBuilder: (context, index) {
            final p = players[index];

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              color: Colors.white,
              child: Row(
                children: [
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
                  SizedBox(
                    width: 75,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p['pos'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
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
