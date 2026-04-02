import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ 파이어베이스 임포트 수정

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
              game['away'].toString().toUpperCase() ==
                  widget.team.id.toUpperCase() ||
              game['home'].toString().toUpperCase() ==
                  widget.team.id.toUpperCase() ||
              game['away'] == widget.team.nameKo ||
              game['home'] == widget.team.nameKo;

          if (isMyMatch) {
            myMatch.add(game);
          } else {
            otherMatches.add(game);
          }
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
              // 메인 카드 영역
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

              // ✅ 타구단 경기 & 순위표 버튼
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

              // 구단 소식 헤더
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

  // 🏆 순위표 바텀 시트 (폰트 및 로고 크기 확대, UI 개선 버전)
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
              // 상단 핸들러 바
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
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ), // 18 -> 19
              ),
              const SizedBox(height: 16),

              // 표 헤더 (글씨 크기 12 -> 13)
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

              // 파이어베이스 데이터 리스트
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('kbo_rankings')
                      .orderBy('rank')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('순위 정보를 불러올 수 없습니다.'));
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;

                        final bool isMyTeam =
                            data['teamName'] == widget.team.nameKo ||
                            data['teamName'] == widget.team.id;

                        return Container(
                          decoration: BoxDecoration(
                            color: isMyTeam
                                ? widget.team.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ), // 간격도 살짝 넓힘 (10 -> 12)
                          child: Row(
                            children: [
                              // 1. 순위 (글씨 크기 14 -> 15)
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

                              // 2. 팀 로고 + 팀명 (로고 22->24, 글씨 14->15)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        _getLogo(data['teamName']),
                                        width: 24, // 로고 확대
                                        height: 24, // 로고 확대
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
                                          fontSize: 15, // 글씨 확대
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

                              // 3. 경기 수 (12 -> 13)
                              SizedBox(
                                width: 35,
                                child: Text(
                                  '${data['games']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),

                              // 4. 승-무-패 (12 -> 13)
                              SizedBox(
                                width: 75,
                                child: Text(
                                  '${data['win']}-${data['draw']}-${data['lose']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),

                              // 5. 승률 (12 -> 13)
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

  Widget _buildMainCard(dynamic game) {
    bool isActuallyToday =
        _selectedDate.year == _today.year &&
        _selectedDate.month == _today.month &&
        _selectedDate.day == _today.day;

    return GestureDetector(
      onTap: game != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LineupScreen(game: game, themeColor: widget.team.primary),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
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
            // 상단 날짜 영역
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
                      color: widget.team.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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

            const Spacer(flex: 1),

            if (game == null)
              const Center(child: Text("예정된 경기가 없습니다."))
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  _teamInfo(game['away']),
                  const Spacer(flex: 2),
                  _vsInfo(game['stadium'], game['time']),
                  const Spacer(flex: 2),
                  _teamInfo(game['home']),
                  const Spacer(flex: 1),
                ],
              ),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _teamInfo(String teamName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          _getLogo(teamName),
          width: 60,
          height: 60,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.sports_baseball, size: 60),
        ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ],
    );
  }

  Widget _vsInfo(String stadium, String time) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 5),
        const Text(
          'VS',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stadium,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
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

  Widget _buildOtherGamesList(List<dynamic> games) {
    if (games.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("경기 정보가 없습니다.")),
      );
    }

    return SizedBox(
      height: 145,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: games.length,
        itemBuilder: (context, i) => Container(
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
                "${games[i]['stadium']} | ${games[i]['time']}",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset(
                    _getLogo(games[i]['away']),
                    width: 35,
                    height: 35,
                  ),
                  const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black12,
                    ),
                  ),
                  Image.asset(
                    _getLogo(games[i]['home']),
                    width: 35,
                    height: 35,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${games[i]['away']} : ${games[i]['home']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 홈 탭 뉴스 프리뷰(1~2개)
  // ✅ 홈 탭 뉴스 프리뷰(네이버 검색 API, 1~2개)
  Widget _buildNewsPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FutureBuilder<List<NaverNewsArticle>>(
        future: _newsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snap.hasError) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '구단 소식을 불러오지 못했어요.',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snap.error}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.team.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _newsFuture = NaverNewsService.fetchTeamNews(
                            teamNameOrId: widget.team.nameKo,
                            start: 1,
                            display: 2,
                            sort: 'date',
                          );
                        });
                      },
                      child: const Text('다시 시도'),
                    ),
                  ),
                ],
              ),
            );
          }

          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(child: Text('표시할 구단 소식이 없어요.')),
            );
          }

          return Column(
            children: [
              for (final a in list) ...[
                _NaverNewsPreviewCard(
                  article: a,
                  themeColor: widget.team.primary,
                  onTap: () {
                    // 프리뷰 클릭 시 -> 더보기 화면으로
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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
                    _domainText(
                      article.originallink.isNotEmpty
                          ? article.originallink
                          : article.link,
                    ),
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

  String _domainText(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.host.replaceFirst('www.', '');
  }
}
