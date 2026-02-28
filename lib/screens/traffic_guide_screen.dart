// lib/screens/traffic_guide_screen.dart

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
    try {
      _locationInfo = stadiumLocations.firstWhere(
        (loc) => loc.id == widget.stadiumId,
      );
    } catch (e) {
      debugPrint('위치 정보 찾기 실패: $e');
    }

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

  List<Map<String, dynamic>> _parseBusInfo(String rawData) {
    if (rawData.isEmpty) return [];
    final List<Map<String, dynamic>> result = [];
    final RegExp regex = RegExp(r'\[(.*?)\](.*?)(?=\[|$)');
    final matches = regex.allMatches(rawData);

    if (matches.isEmpty) {
      return [
        {
          'stop': '버스 정류장',
          'buses': [rawData],
        },
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.stadiumName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.themeColor))
          : Stack(
              children: [
                // 배경 이미지 영역
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/view_img/${widget.stadiumId}_view.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    padding: const EdgeInsets.only(bottom: 100),
                    alignment: Alignment.center,
                  ),
                ),

                // 정보 패널
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.15,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ✅ 1. 탭바 색상 수정: 붉은색(themeColor)을 빼고 무채색으로 변경
                          TabBar(
                            controller: _tabController,
                            labelColor:
                                Colors.black87, // ✅ 선택된 탭 텍스트/아이콘 색상 (검정)
                            unselectedLabelColor:
                                Colors.grey.shade400, // ✅ 선택 안 된 탭 (연한 회색)
                            indicatorColor: Colors.black87, // ✅ 인디케이터 색상 (검정)
                            indicatorWeight: 3,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            tabs: const [
                              Tab(icon: Icon(Icons.subway), text: '지하철'),
                              Tab(icon: Icon(Icons.directions_bus), text: '버스'),
                              Tab(icon: Icon(Icons.local_parking), text: '주차'),
                            ],
                          ),

                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildPrettyTab(
                                  scrollController,
                                  Icons.subway,
                                  '지하철 이용 시',
                                  _trafficInfo['subway'],
                                ),
                                _buildBusTab(scrollController),
                                _buildPrettyTab(
                                  scrollController,
                                  Icons.local_parking,
                                  '자차 이용 시',
                                  _trafficInfo['parking'],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildPrettyTab(
    ScrollController sc,
    IconData icon,
    String title,
    String? content,
  ) {
    return ListView(
      controller: sc,
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            // ✅ 2. 섹션 타이틀 아이콘 수정: themeColor 대신 검정색 사용
            Icon(icon, color: Colors.black87, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _cardHeader('상세 안내'),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  content ?? '정보가 없습니다.',
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
    );
  }

  Widget _buildBusTab(ScrollController sc) {
    final busDataList = _parseBusInfo(_trafficInfo['bus'] ?? '');

    return ListView(
      controller: sc,
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            // ✅ 3. 버스 탭 아이콘 색상 수정
            Icon(Icons.directions_bus, color: Colors.black87, size: 28),
            const SizedBox(width: 8),
            const Text(
              '버스 이용 시',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...busDataList.map((data) {
          final stopName = data['stop'] as String;
          final buses = data['buses'] as List<String>;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardHeader(stopName, icon: Icons.place),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: buses
                          .map((busNum) => _busChip(busNum))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // ✅ 4. 카드 헤더 디자인: 배경과 아이콘 모두 무채색으로 변경
  Widget _cardHeader(String title, {IconData icon = Icons.info_outline}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA), // 연한 회색 배경
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54), // 연한 검정 아이콘
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  Widget _busChip(String busNum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
  }
}
