import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../team_theme.dart';
import '../../services/naver_news_service.dart';
import '../../models/naver_news_article.dart';
import '../lineup_screen.dart';
import 'package:jikgwan_mate/screens/team_news_screen.dart';

class HomeTab extends StatefulWidget {
  final String uid;
  final TeamTheme team;

  const HomeTab({super.key, required this.uid, required this.team});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late PageController _pageController;
  final int _initialPage = 500;
  double _currentPage = 500;

  final DateTime _today = DateTime.now();
  late DateTime _baseDate;
  late DateTime _selectedDate;
  late Future<Map<String, List<dynamic>>> _gameData;
  late Future<List<NaverNewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _baseDate = DateTime(_today.year, _today.month, _today.day);
    _selectedDate = _baseDate;

    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.85,
    );

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });

    _gameData = _loadGamesFromCsv(_selectedDate);
    _newsFuture = NaverNewsService.fetchTeamNews(
      teamNameOrId: widget.team.nameKo,
      start: 1,
      display: 2,
      sort: 'date',
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedDate = _baseDate.add(Duration(days: index - _initialPage));
      _gameData = _loadGamesFromCsv(_selectedDate);
    });
  }

  String _getLogo(String teamName) {
    String logo = 'assets/team_logo_img/ssg.png';
    teamThemes.forEach((k, v) {
      if (v.nameKo == teamName ||
          v.id.toUpperCase() == teamName.toUpperCase()) {
        logo = v.logoPath;
      }
    });
    return logo;
  }

  bool _isMyTeam(String teamName) {
    final String tName = teamName.toUpperCase().trim();
    final String myId = widget.team.id.toUpperCase().trim();
    final String myKo = widget.team.nameKo.trim();

    if (tName == myId || tName == myKo) return true;
    if ((tName.contains('KIA') || tName.contains('기아')) &&
        (myId.contains('KIA') || myKo.contains('기아')))
      return true;
    if ((tName.contains('KT') || tName.contains('케이티')) &&
        (myId.contains('KT') || myKo.contains('케이티')))
      return true;
    if ((tName.contains('NC') || tName.contains('엔씨')) &&
        (myId.contains('NC') || myKo.contains('엔씨')))
      return true;
    if ((tName.contains('SSG') || tName.contains('에스에스지')) &&
        (myId.contains('SSG') || myKo.contains('에스에스지')))
      return true;
    if ((tName.contains('LG') || tName.contains('엘지')) &&
        (myId.contains('LG') || myKo.contains('엘지')))
      return true;

    return false;
  }

  String _getKboGameId(DateTime date, String away, String home) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    String getCode(String t) {
      if (t.contains('SSG') || t.contains('에스에스지')) return 'SK';
      if (t.contains('삼성')) return 'SS';
      if (t.contains('두산')) return 'OB';
      if (t.contains('KIA') || t.contains('기아')) return 'HT';
      if (t.contains('LG') || t.contains('엘지')) return 'LG';
      if (t.contains('NC') || t.contains('엔씨')) return 'NC';
      if (t.contains('롯데')) return 'LT';
      if (t.contains('키움')) return 'WO';
      if (t.contains('한화')) return 'HH';
      if (t.contains('KT') || t.contains('케이티')) return 'KT';
      return t;
    }

    return "$y$m$d${getCode(away)}${getCode(home)}0";
  }

  Future<Map<String, List<dynamic>>> _loadGamesFromCsv(DateTime date) async {
    try {
      final rawData = await rootBundle.loadString('assets/data/games.csv');
      final lines = rawData.replaceAll('\r', '').split('\n');
      final String targetDate = "${date.year}.${date.month}.${date.day}";

      List<dynamic> myMatch = [];
      List<dynamic> otherMatches = [];

      for (int i = 1; i < lines.length; i++) {
        final cells = lines[i].split(',');
        if (cells.length < 5) continue;

        final game = {
          'date': cells[0].trim(),
          'stadium': cells[1].trim(),
          'away': cells[3].trim(),
          'home': cells[4].trim(),
          'time': (cells.length > 5 && cells[5].trim().isNotEmpty)
              ? cells[5].trim()
              : "18:30",
        };

        if (game['date'] == targetDate) {
          bool isMyMatch =
              _isMyTeam(game['away'].toString()) ||
              _isMyTeam(game['home'].toString());
          if (isMyMatch)
            myMatch.add(game);
          else
            otherMatches.add(game);
        }
      }
      return {'my': myMatch, 'others': otherMatches};
    } catch (e) {
      return {'my': [], 'others': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: _gameData,
      builder: (context, snapshot) {
        final myMatch = snapshot.data?['my']?.isNotEmpty == true
            ? snapshot.data!['my']![0]
            : null;
        final otherMatches = snapshot.data?['others'] ?? [];

        return Scaffold(
          backgroundColor: Colors.white,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 290,
                child: Stack(
                  children: [
                    Container(height: 145, color: widget.team.primary),
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        double value = (index - _currentPage).abs();
                        double scale = (1 - (value * 0.12)).clamp(0.85, 1.0);
                        double verticalOffset = value * 25;

                        return Transform.translate(
                          offset: Offset(0, verticalOffset),
                          child: Transform.scale(
                            scale: scale,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 20,
                              ),
                              child: _buildMainCard(myMatch),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '타구단 경기',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showKboRankingSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.team.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 16,
                              color: widget.team.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '팀 순위',
                              style: TextStyle(
                                color: widget.team.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildOtherGamesList(otherMatches),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 10, 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '최신 구단 소식',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamNewsScreen(
                              teamName: widget.team.nameKo,
                              themeColor: widget.team.primary,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        '더보기 >',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              _buildNewsPreview(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _showKboRankingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'KBO 정규시즌 순위',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 35,
                    child: Text(
                      '순위',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        '팀명',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 35,
                    child: Text(
                      '경기',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 75,
                    child: Text(
                      '승-무-패',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 45,
                    child: Text(
                      '승률',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('kbo_rankings')
                      .orderBy('rank')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                      return const Center(child: Text('순위 정보를 불러올 수 없습니다.'));
                    final docs = snapshot.data!.docs;
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final bool isMyTeam = _isMyTeam(
                          data['teamName'].toString(),
                        );
                        return Container(
                          decoration: BoxDecoration(
                            color: isMyTeam
                                ? widget.team.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 35,
                                child: Text(
                                  '${data['rank']}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isMyTeam
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    color: isMyTeam
                                        ? widget.team.primary
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        _getLogo(data['teamName']),
                                        width: 24,
                                        height: 24,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.sports_baseball,
                                              size: 24,
                                              color: Colors.grey,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${data['teamName']}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isMyTeam
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isMyTeam
                                              ? widget.team.primary
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 35,
                                child: Text(
                                  '${data['games']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                width: 75,
                                child: Text(
                                  '${data['win']}-${data['draw']}-${data['lose']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                width: 45,
                                child: Text(
                                  '${data['winRate']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // ⭐️ 메인 경기 카드
  // ==========================================
  Widget _buildMainCard(dynamic game) {
    if (game == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(child: Text("경기가 없습니다.")),
      );
    }

    bool isActuallyToday =
        _selectedDate.year == _today.year &&
        _selectedDate.month == _today.month &&
        _selectedDate.day == _today.day;
    final String scoreDocId = _getKboGameId(
      _selectedDate,
      game['away'],
      game['home'],
    );

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kbo_scoreboards')
          .doc(scoreDocId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? scoreData =
            snapshot.data?.data() as Map<String, dynamic>?;

        String awayScore = "0";
        String homeScore = "0";
        bool isFinished = scoreData?['status'] == 'FINISHED';

        if (scoreData != null && scoreData['scoreboard'] != null) {
          final scoreboardList = scoreData['scoreboard'] as List<dynamic>;
          if (scoreboardList.length >= 2) {
            awayScore = scoreboardList[0]['R']?.toString() ?? "0";
            homeScore = scoreboardList[1]['R']?.toString() ?? "0";
          }
        }

        bool hasScore =
            isFinished ||
            (scoreData != null && scoreData['scoreboard'] != null);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LineupScreen(game: game, themeColor: widget.team.primary),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isActuallyToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isFinished ? Colors.grey : widget.team.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isFinished ? '경기 종료' : 'Today',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 27),
                    Text(
                      "${_selectedDate.year}.${_selectedDate.month}.${_selectedDate.day}",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _teamInfo(game['away'])),

                    if (hasScore)
                      _scoreArea(
                        awayScore,
                        homeScore,
                        game['stadium'].toString(),
                      )
                    else
                      _vsOriginalArea(
                        game['stadium'].toString(),
                        game['time'].toString(),
                      ),

                    Expanded(child: _teamInfo(game['home'])),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔢 점수 표시 영역 (강렬한 색상 버전)
  Widget _scoreArea(String awayScore, String homeScore, String stadium) {
    int a = int.tryParse(awayScore) ?? 0;
    int h = int.tryParse(homeScore) ?? 0;

    // 🔥 강렬한 색상 정의
    const Color strongRed = Color(0xFFCC0000); // 강렬한 빨강

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              awayScore,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: a > h
                    ? strongRed
                    : (a < h ? Colors.black : Colors.black87),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'vs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: Colors.black45,
                ),
              ),
            ),
            Text(
              homeScore,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: h > a
                    ? strongRed
                    : (h < a ? Colors.black : Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          stadium.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // 🆚 오리지널 VS 영역 (미래 경기용)
  Widget _vsOriginalArea(String stadium, String time) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'VS',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stadium.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _teamInfo(String teamName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          _getLogo(teamName),
          width: 55,
          height: 55,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.sports_baseball, size: 55),
        ),
        const SizedBox(height: 10),
        Text(
          teamName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }

  // ==========================================
  // ⭐️ 타구단 경기 리스트
  // ==========================================
  Widget _buildOtherGamesList(List<dynamic> games) {
    if (games.isEmpty)
      return const SizedBox(
        height: 100,
        child: Center(child: Text("경기 정보가 없습니다.")),
      );
    return SizedBox(
      height: 145,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: games.length,
        itemBuilder: (context, i) {
          final game = games[i];
          final String scoreDocId = _getKboGameId(
            _selectedDate,
            game['away'],
            game['home'],
          );
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('kbo_scoreboards')
                .doc(scoreDocId)
                .snapshots(),
            builder: (context, snapshot) {
              Map<String, dynamic>? scoreData =
                  snapshot.data?.data() as Map<String, dynamic>?;
              String awayScore = "0", homeScore = "0";
              bool isFinished = scoreData?['status'] == 'FINISHED';
              if (scoreData != null && scoreData['scoreboard'] != null) {
                final list = scoreData['scoreboard'] as List<dynamic>;
                if (list.length >= 2) {
                  awayScore = list[0]['R']?.toString() ?? "0";
                  homeScore = list[1]['R']?.toString() ?? "0";
                }
              }
              bool hasScore =
                  isFinished ||
                  (scoreData != null && scoreData['scoreboard'] != null);
              int a = int.tryParse(awayScore) ?? 0,
                  h = int.tryParse(homeScore) ?? 0;

              const Color strongRed = Color(0xFFCC0000);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LineupScreen(game: game, themeColor: Colors.grey),
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 15, bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isFinished
                            ? '종료'
                            : "${game['stadium']} | ${game['time']}",
                        style: TextStyle(
                          fontSize: 10,
                          color: isFinished ? Colors.grey : Colors.grey,
                          fontWeight: isFinished
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Image.asset(
                            _getLogo(game['away']),
                            width: 35,
                            height: 35,
                          ),
                          if (hasScore)
                            Row(
                              children: [
                                Text(
                                  awayScore,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: a > h
                                        ? strongRed
                                        : (a < h ? Colors.black : Colors.black),
                                  ),
                                ),
                                const Text(
                                  ' vs ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black45,
                                  ),
                                ),
                                Text(
                                  homeScore,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: h > a
                                        ? strongRed
                                        : (h < a ? Colors.black : Colors.black),
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'VS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.black45,
                              ),
                            ),
                          Image.asset(
                            _getLogo(game['home']),
                            width: 35,
                            height: 35,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${game['away']} : ${game['home']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNewsPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FutureBuilder<List<NaverNewsArticle>>(
        future: _newsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          final list = snap.data ?? [];
          if (list.isEmpty)
            return const SizedBox(
              height: 180,
              child: Center(child: Text('소식이 없어요.')),
            );
          return Column(
            children: [
              for (final a in list) ...[
                _NaverNewsPreviewCard(
                  article: a,
                  themeColor: widget.team.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamNewsScreen(
                          teamName: widget.team.nameKo,
                          themeColor: widget.team.primary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NaverNewsPreviewCard extends StatelessWidget {
  final NaverNewsArticle article;
  final Color themeColor;
  final VoidCallback onTap;
  const _NaverNewsPreviewCard({
    required this.article,
    required this.themeColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.public, size: 15, color: themeColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    article.originallink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
