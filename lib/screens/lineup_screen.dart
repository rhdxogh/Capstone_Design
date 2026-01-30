import 'package:flutter/material.dart';
import '../team_theme.dart';

class LineupScreen extends StatefulWidget {
  final dynamic game;
  final Color themeColor;

  const LineupScreen({super.key, required this.game, required this.themeColor});

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '오늘의 경기',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // ✅ 전체 스크롤을 넣어 작은 화면에서도 짤림 방지
        child: Column(
          children: [
            _buildGameHeader(),

            // ✅ 타이틀과 버튼 그룹
            _buildCompactSelector(),

            // ✅ 세로형 배경에 맞춘 야구장 영역
            SizedBox(
              height: 520, // 새로운 세로형 이미지에 맞춰 높이 최적화
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFieldLayout(isHome: true),
                  _buildFieldLayout(isHome: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _teamHeaderInfo(widget.game['away'], '양현종'),
          _stadiumInfo(),
          _teamHeaderInfo(widget.game['home'], '김광현'),
        ],
      ),
    );
  }

  Widget _teamHeaderInfo(String teamName, String pitcher) {
    return Column(
      children: [
        Image.asset(_getLogo(teamName), width: 45, height: 45),
        const SizedBox(height: 4),
        Text(
          teamName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        Text(pitcher, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _stadiumInfo() {
    return Column(
      children: [
        Text(
          widget.game['stadium'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: widget.themeColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            widget.game['time'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Home/Away 버튼 짤림 해결: 너비를 200으로 넓히고 간격 조정
  Widget _buildCompactSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 5, 25, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '라인업',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Container(
            height: 38,
            width: 200, // ✅ 짤리지 않게 폭을 충분히 확보
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: widget.themeColor,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Home'),
                Tab(text: 'Away'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 새로운 세로형 배경에 맞춘 정밀 좌표 배치
  Widget _buildFieldLayout({required bool isHome}) {
    return Center(
      child: Container(
        width: 380,
        height: 500,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🏟️ 새로 자른 세로형 배경 이미지 적용
            Image.asset(
              'assets/lineup_img/stadiumbackground.png',
              width: 320,
              fit: BoxFit.contain,
            ),

            // ✅ 핵심 포지션 정밀 배치 (1B, 2B, C, SP 엄수)
            _playerTag(
              top: 310,
              img: 'sp.png',
              name: isHome ? '김광현' : '양현종',
              order: '',
            ), // 투수 마운드
            _playerTag(
              bottom: 50,
              img: 'c.png',
              name: '조형우',
              order: '9',
            ), // 홈 플레이트
            _playerTag(
              top: 235,
              img: '2b.png',
              name: '정준재',
              order: '8',
            ), // 2루 베이스
            _playerTag(
              top: 310,
              right: 35,
              img: '1b.png',
              name: '고명준',
              order: '5',
            ), // 1루 베이스
            // 나머지 포지션
            _playerTag(
              top: 265,
              left: 80,
              img: 'ss.png',
              name: '박성한',
              order: '1',
            ), // 유격수
            _playerTag(
              top: 310,
              left: 35,
              img: '3b.png',
              name: '최 정',
              order: '3',
            ), // 3루 베이스
            _playerTag(
              top: 195,
              left: 20,
              img: 'lf.png',
              name: '에레디아',
              order: '4',
            ), // 좌익수
            _playerTag(
              top: 195,
              right: 20,
              img: 'rf.png',
              name: '김성욱',
              order: '7',
            ), // 우익수
            _playerTag(top: 125, img: 'cf.png', name: '최지훈', order: '6'), // 중견수
            _playerTag(
              bottom: 10,
              right: 30,
              img: 'dh.png',
              name: '한유섬',
              order: '4',
            ), // 지명타자
          ],
        ),
      ),
    );
  }

  Widget _playerTag({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required String img,
    required String name,
    required String order,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/lineup_img/$img',
              width: 85,
              fit: BoxFit.contain,
            ), // 배지 크기 살짝 키움
            SizedBox(
              width: 85,
              height: 24,
              child: Row(
                children: [
                  const Expanded(flex: 2, child: SizedBox()),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        order,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
