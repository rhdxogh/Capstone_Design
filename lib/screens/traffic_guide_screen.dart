import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../data/stadium_locations.dart';

class TrafficGuideScreen extends StatefulWidget {
  final String stadiumId;
  final String stadiumName;
  final Color themeColor;

  const TrafficGuideScreen({
    super.key,
    required this.stadiumId,
    required this.stadiumName,
    required this.themeColor,
  });

  @override
  State<TrafficGuideScreen> createState() => _TrafficGuideScreenState();
}

class _TrafficGuideScreenState extends State<TrafficGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String> _trafficInfo = {};
  bool _isLoading = true;
  StadiumLoc? _locationInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. 위치 정보 찾기
    try {
      _locationInfo = stadiumLocations.firstWhere(
        (loc) => loc.id == widget.stadiumId,
      );
    } catch (e) {
      debugPrint('위치 정보 찾기 실패: $e');
    }

    // 2. CSV 데이터 로드
    try {
      final String csvData = await rootBundle.loadString(
        'assets/data/guide.csv',
      );
      final List<String> lines = csvData.split('\n');
      final RegExp csvSplitter = RegExp(r',(?=(?:[^"]*"[^"]*")*[^"]*$)');

      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        List<String> row = line.split(csvSplitter).map((e) {
          return e.trim().replaceAll('"', '');
        }).toList();

        if (row.length >= 4) {
          if (row[0].toLowerCase() == widget.stadiumId.toLowerCase()) {
            setState(() {
              _trafficInfo = {
                'subway': row[1].replaceAll('\\n', '\n'),
                'bus': row[2].replaceAll('\\n', '\n'),
                'parking': row[3].replaceAll('\\n', '\n'),
              };
              _isLoading = false;
            });
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('CSV 로드 에러: $e');
      setState(() => _isLoading = false);
    }
  }

  // 🚌 버스 정보 파싱 로직
  List<Map<String, dynamic>> _parseBusInfo(String rawData) {
    if (rawData.isEmpty) return [];
    final List<Map<String, dynamic>> result = [];
    final RegExp regex = RegExp(r'\[(.*?)\](.*?)(?=\[|$)');
    final matches = regex.allMatches(rawData);

    if (matches.isEmpty) {
      return [
        {'stop': '버스 정류장', 'buses': rawData},
      ];
    }

    for (final match in matches) {
      String stopName = match.group(1)?.trim() ?? '';
      String busString = match.group(2)?.trim() ?? '';
      List<String> busList = busString
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      result.add({'stop': stopName, 'buses': busList});
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.stadiumName),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.themeColor))
          : Column(
              children: [
                // ✅ 1. 상단 지도 플레이스홀더 (아까 그 디자인으로 복구)
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // 지도 들어갈 자리 (회색 박스)
                      Container(
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.stadiumName}\n(${_locationInfo?.address ?? "주소 정보 없음"})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 하단 둥근 처리
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. 탭바
                TabBar(
                  controller: _tabController,
                  labelColor: widget.themeColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: widget.themeColor,
                  indicatorWeight: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: const [
                    Tab(icon: Icon(Icons.subway), text: '지하철'),
                    Tab(icon: Icon(Icons.directions_bus), text: '버스'),
                    Tab(icon: Icon(Icons.local_parking), text: '주차'),
                  ],
                ),

                // 3. 내용
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ✅ 예뻐진 지하철 탭
                      _buildPrettyTab(
                        icon: Icons.subway,
                        title: '지하철 이용 시',
                        content: _trafficInfo['subway'],
                      ),

                      // ✅ 타이틀 추가된 버스 탭
                      _buildBusTab(_trafficInfo['bus']),

                      // ✅ 예뻐진 주차 탭
                      _buildPrettyTab(
                        icon: Icons.local_parking,
                        title: '자차 이용 시',
                        content: _trafficInfo['parking'],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ✅ [NEW] 지하철/주차를 위한 예쁜 카드 빌더
  Widget _buildPrettyTab({
    required IconData icon,
    required String title,
    required String? content,
  }) {
    if (content == null || content.isEmpty) {
      return const Center(child: Text("정보가 없습니다."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 타이틀 (아이콘 + 텍스트)
          Row(
            children: [
              Icon(icon, color: widget.themeColor, size: 28),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 정보 카드 (버스 카드와 디자인 통일)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 카드 헤더 (테마색 배경)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: widget.themeColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '상세 안내',
                        style: TextStyle(
                          color: widget.themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                // 내용 텍스트
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🚌 버스 탭 UI 빌더
  Widget _buildBusTab(String? content) {
    if (content == null || content.isEmpty) {
      return const Center(child: Text("정보가 없습니다."));
    }

    final busDataList = _parseBusInfo(content);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ✅ 1. 버스 탭에도 타이틀 추가!
        Row(
          children: [
            Icon(Icons.directions_bus, color: widget.themeColor, size: 28),
            const SizedBox(width: 8),
            const Text(
              '버스 이용 시',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. 버스 정류장 리스트
        ...busDataList.map((data) {
          final stopName = data['stop'] as String;
          final buses = data['buses'] as List<String>;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20), // 카드 사이 간격
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 정류장 이름 헤더
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.themeColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place, size: 18, color: widget.themeColor),
                        const SizedBox(width: 6),
                        Text(
                          stopName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 버스 번호 칩들
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: buses.map((busNum) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            busNum,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(), // List.map 끝
      ],
    );
  }
}
