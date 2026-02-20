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
    // 1. 위치 정보 찾기 (data/stadium_locations.dart 활용)
    try {
      _locationInfo = stadiumLocations.firstWhere(
        (loc) => loc.id == widget.stadiumId,
      );
    } catch (e) {
      debugPrint('위치 정보 찾기 실패: $e');
    }

    // 2. CSV 데이터 로드 및 파싱 (guide.csv 활용)
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

  // 버스 정보를 [정류장]과 번호들로 나누는 로직
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
        title: Text(widget.stadiumName),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.themeColor))
          : Stack(
              children: [
                // ✅ 1. 배경 영역: 지도 플레이스홀더
                /*Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[200],
                  padding: const EdgeInsets.only(bottom: 100), // 패널에 가려지지 않게 보정
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.stadiumName}\n(${_locationInfo?.address ?? "주소 정보 없음"})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '지도를 연동하면 여기에 실제 지도가 표시됩니다.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                */
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      // 💡 viewImagePath나 stadium_img 등 이미 있는 에셋 경로를 활용하세요!
                      image: AssetImage(
                        'assets/view_img/${widget.stadiumId}_view.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 사진 위에 살짝 어두운 필터를 깔아주면 하단 하얀색 패널이 더 돋보입니다.
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    padding: const EdgeInsets.only(bottom: 100),
                    alignment: Alignment.center,
                  ),
                ),

                // ✅ 2. 전경 영역: 슬라이딩 정보 패널
                DraggableScrollableSheet(
                  initialChildSize: 0.4, // 초기 높이 (40%)
                  minChildSize: 0.15, // 최소 높이 (15%)
                  maxChildSize: 0.95, // 최대 높이 (95%)
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
                          // 핸들러 바
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

                          // 탭바
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

                          // 탭 내용
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

  // ✅ 지하철/주차용 예쁜 카드 위젯
  Widget _buildPrettyTab(
    ScrollController sc,
    IconData icon,
    String title,
    String? content,
  ) {
    return ListView(
      controller: sc, // 패널 스크롤 연동
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Icon(icon, color: widget.themeColor, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  // ✅ 버스 전용 탭 위젯
  Widget _buildBusTab(ScrollController sc) {
    final busDataList = _parseBusInfo(_trafficInfo['bus'] ?? '');

    return ListView(
      controller: sc, // 패널 스크롤 연동
      padding: const EdgeInsets.all(24),
      children: [
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

  // 공통 카드 헤더 디자인
  Widget _cardHeader(String title, {IconData icon = Icons.info_outline}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.themeColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: widget.themeColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: widget.themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // 공통 카드 장식 디자인
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

  // 버스 번호 칩 디자인
  Widget _busChip(String busNum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
  }
}
