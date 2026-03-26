import 'package:flutter/material.dart';

import '../data/stadium_locations.dart';
import '../models/stadium_weather.dart';
import '../services/weather_service.dart';
import 'weather_detail_screen.dart';
import 'kma_radar_screen.dart';

class WeatherMapScreen extends StatefulWidget {
  final Color themeColor;

  /// 지도 이미지 에셋 경로
  final String mapAsset;

  const WeatherMapScreen({
    super.key,
    required this.themeColor,
    this.mapAsset = 'assets/etc/korea_map.png',
  });

  @override
  State<WeatherMapScreen> createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends State<WeatherMapScreen> {
  late Future<List<StadiumWeather>> _future;

  @override
  void initState() {
    super.initState();
    _future = WeatherService.fetchAll();
  }

  void _refresh() {
    setState(() => _future = WeatherService.fetchAll());
  }

  StadiumLoc _findStadium(String id) {
    return stadiumLocations.firstWhere((s) => s.id == id);
  }

  // ✅ 지도에 표시할 "짧은 이름"으로 변환
  String _shortName(String fullName) {
    if (fullName.contains('수원')) return '수원';
    if (fullName.contains('잠실')) return '잠실';
    if (fullName.contains('고척')) return '고척';
    if (fullName.contains('문학') ||
        fullName.contains('인천') ||
        fullName.contains('SSG'))
      return '문학';
    if (fullName.contains('대전')) return '대전';
    if (fullName.contains('대구')) return '대구';
    if (fullName.contains('창원')) return '창원';
    if (fullName.contains('사직') || fullName.contains('부산')) return '사직';
    if (fullName.contains('광주')) return '광주';
    return fullName;
  }

  /// ✅ OpenWeather icon code(01d, 02n...) -> assets/weather_img 아이콘 매핑
  String _assetIconPath(StadiumWeather w) {
    final icon = w.icon.toLowerCase(); // ex) 01d, 02n...

    if (icon.startsWith('01')) return 'assets/weather_img/sun.png';
    if (icon.startsWith('02')) return 'assets/weather_img/sunandcloud.png';
    if (icon.startsWith('03') || icon.startsWith('04'))
      return 'assets/weather_img/cloud.png';
    if (icon.startsWith('09') || icon.startsWith('10'))
      return 'assets/weather_img/rain.png';
    if (icon.startsWith('11'))
      return 'assets/weather_img/rain.png'; // thunderstorm 대체
    if (icon.startsWith('13')) return 'assets/weather_img/snow.png';
    if (icon.startsWith('50'))
      return 'assets/weather_img/cloud.png'; // mist/fog 대체

    return 'assets/weather_img/sun.png';
  }

  // ✅ 구장별 "미세 오프셋"
  final Map<String, Offset> _markerOffsets = const {
    'munhak': Offset(-26, -10),
    'gocheok': Offset(-6, -42),
    'jamsil': Offset(24, -18),
    'suwon': Offset(18, 18),

    'daejeon': Offset(0, 0),
    'daegu': Offset(0, 0),
    'changwon': Offset(0, 0),
    'sajik': Offset(0, 0),
    'gwangju': Offset(0, 0),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '실시간 날씨 지도',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      // 🌟 AppBar 밖으로 빼낸 레이더 영상 버튼! (Scaffold의 속성입니다)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: widget.themeColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => KmaRadarScreen(themeColor: widget.themeColor),
            ),
          );
        },
        icon: const Icon(Icons.radar, color: Colors.white),
        label: const Text(
          '기상청 레이더 보기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<StadiumWeather>>(
          future: _future,
          // ... (이하 기존 코드와 완전히 동일합니다) ...
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _ErrorView(
                themeColor: widget.themeColor,
                message: '날씨를 불러오지 못했어요.\n${snap.error}',
                onRetry: _refresh,
              );
            }

            final weathers = snap.data ?? [];
            if (weathers.isEmpty) {
              return _ErrorView(
                themeColor: widget.themeColor,
                message: '데이터가 비어있어요. 새로고침 해주세요.',
                onRetry: _refresh,
              );
            }

            weathers.sort((a, b) => a.stadiumId.compareTo(b.stadiumId));

            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                                color: Colors.black.withOpacity(0.06),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final w = box.maxWidth;
                                final h = box.maxHeight;

                                final mapHeight = (h * 0.90).clamp(200.0, h);
                                final mapWidth = w;

                                final markers = _buildMarkers(weathers);

                                return Column(
                                  children: [
                                    SizedBox(
                                      width: mapWidth,
                                      height: mapHeight,
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: Image.asset(
                                                widget.mapAsset,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) {
                                                  return Center(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            12,
                                                          ),
                                                      child: Text(
                                                        '지도 이미지를 찾을 수 없어요.\n${widget.mapAsset}\n\n(pubspec.yaml assets 등록/경로 확인)',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),

                                          // ✅ 마커들 (Fraction 기반 배치 + 오프셋 적용)
                                          for (final m in markers)
                                            Positioned(
                                              left:
                                                  (m.dx * mapWidth) +
                                                  (_markerOffsets[m.stadiumId]
                                                          ?.dx ??
                                                      0),
                                              top:
                                                  (m.dy * mapHeight) +
                                                  (_markerOffsets[m.stadiumId]
                                                          ?.dy ??
                                                      0),
                                              child: _MarkerCard(
                                                themeColor: widget.themeColor,
                                                label: m.label,
                                                assetIconPath: m.assetIconPath,
                                                tempText: m.tempText,
                                                onTap: m.onTap,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '마커를 누르면 해당 구장 상세 날씨로 이동해요',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.grey.shade700,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<_MarkerModel> _buildMarkers(List<StadiumWeather> weathers) {
    _MarkerModel make({
      required String stadiumId,
      required double dx,
      required double dy,
    }) {
      final w = weathers.firstWhere((e) => e.stadiumId == stadiumId);
      final s = _findStadium(stadiumId);

      return _MarkerModel(
        stadiumId: stadiumId,
        dx: dx,
        dy: dy,
        label: _shortName(s.nameKo),
        assetIconPath: _assetIconPath(w),
        tempText: '${w.temp.round()}°',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WeatherDetailScreen(
                stadium: s,
                stadiumName: s.nameKo,
                themeColor: widget.themeColor,
              ),
            ),
          );
        },
      );
    }

    final markers = <_MarkerModel>[
      make(stadiumId: 'gocheok', dx: 0.24, dy: 0.26),
      make(stadiumId: 'jamsil', dx: 0.28, dy: 0.27),
      make(stadiumId: 'munhak', dx: 0.18, dy: 0.25),
      make(stadiumId: 'suwon', dx: 0.20, dy: 0.30),
      make(stadiumId: 'daejeon', dx: 0.35, dy: 0.45),
      make(stadiumId: 'daegu', dx: 0.62, dy: 0.48),
      make(stadiumId: 'changwon', dx: 0.55, dy: 0.63),
      make(stadiumId: 'sajik', dx: 0.70, dy: 0.66),
      make(stadiumId: 'gwangju', dx: 0.16, dy: 0.60),
    ];

    final exists = weathers.map((e) => e.stadiumId).toSet();
    return markers.where((m) => exists.contains(m.stadiumId)).toList();
  }
}

class _MarkerModel {
  final String stadiumId;
  final double dx; // 0~1
  final double dy; // 0~1
  final String label;
  final String assetIconPath;
  final String tempText;
  final VoidCallback onTap;

  _MarkerModel({
    required this.stadiumId,
    required this.dx,
    required this.dy,
    required this.label,
    required this.assetIconPath,
    required this.tempText,
    required this.onTap,
  });
}

/// ✅ 아이콘 → 온도 → 지역이름 세로 배치 (asset 아이콘 버전)
class _MarkerCard extends StatelessWidget {
  final Color themeColor;
  final String label;
  final String assetIconPath;
  final String tempText;
  final VoidCallback onTap;

  const _MarkerCard({
    required this.themeColor,
    required this.label,
    required this.assetIconPath,
    required this.tempText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 58,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColor.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 4),
                color: Colors.black.withOpacity(0.10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                assetIconPath,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.cloud, size: 18, color: themeColor),
              ),
              const SizedBox(height: 2),
              Text(
                tempText,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Color themeColor;
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.themeColor,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: onRetry,
                  child: const Text('다시 시도'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
