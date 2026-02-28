import 'package:flutter/material.dart';

import '../../data/stadium_locations.dart';
import '../../models/stadium_weather.dart';
import '../../services/weather_service.dart';
import '../weather_map_screen.dart';
import '../weather_detail_screen.dart';

class WeatherTab extends StatefulWidget {
  final Color teamColor;
  const WeatherTab({super.key, required this.teamColor});

  @override
  State<WeatherTab> createState() => _WeatherTabState();
}

class _WeatherTabState extends State<WeatherTab> {
  late Future<List<StadiumWeather>> _future;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = WeatherService.fetchAll();
      _lastUpdated = DateTime.now();
    });
  }

  String _timeText(DateTime? dt) {
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  StadiumLoc _findStadium(String id) {
    return stadiumLocations.firstWhere((s) => s.id == id);
  }

  String _assetIconPath(StadiumWeather w) {
    final icon = (w.icon).toLowerCase();
    final desc = (w.description).toLowerCase();

    if (icon.startsWith('01')) return 'assets/weather_img/sun.png';
    if (icon.startsWith('02')) return 'assets/weather_img/sunandcloud.png';
    if (icon.startsWith('03') || icon.startsWith('04')) {
      return 'assets/weather_img/cloud.png';
    }
    if (icon.startsWith('09') || icon.startsWith('10')) {
      return 'assets/weather_img/rain.png';
    }
    if (icon.startsWith('11')) return 'assets/weather_img/rain.png';
    if (icon.startsWith('13')) return 'assets/weather_img/snow.png';
    if (icon.startsWith('50')) return 'assets/weather_img/cloud.png';

    if (desc.contains('rain') || desc.contains('비'))
      return 'assets/weather_img/rain.png';
    if (desc.contains('snow') || desc.contains('눈'))
      return 'assets/weather_img/snow.png';
    if (desc.contains('cloud') || desc.contains('구름'))
      return 'assets/weather_img/cloud.png';

    return 'assets/weather_img/sun.png';
  }

  void _goDetail(StadiumLoc stadium) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherDetailScreen(
          stadium: stadium,
          stadiumName: stadium.nameKo,
          themeColor: widget.teamColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            '전국 구장 날씨',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              _TopWeatherCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WeatherMapScreen(themeColor: widget.teamColor),
                    ),
                  );
                },
                lastUpdatedText: _timeText(_lastUpdated),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      '오늘의 구장별 날씨',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _lastUpdated == null
                        ? ''
                        : '업데이트 ${_timeText(_lastUpdated)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<StadiumWeather>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _LoadingList();
                  }

                  if (snapshot.hasError) {
                    return _ErrorBox(
                      message: '날씨를 불러오지 못했어요.',
                      onRetry: _refresh,
                    );
                  }

                  final list = snapshot.data ?? [];
                  list.sort((a, b) => a.stadiumId.compareTo(b.stadiumId));

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < list.length; i++) ...[
                          _WeatherRow(
                            stadium: _findStadium(list[i].stadiumId),
                            weather: list[i],
                            assetIconPath: _assetIconPath(list[i]),
                            onTap: () =>
                                _goDetail(_findStadium(list[i].stadiumId)),
                          ),
                          if (i != list.length - 1)
                            Divider(
                              height: 1,
                              color: Colors.grey.shade100,
                              indent: 16,
                              endIndent: 16,
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopWeatherCard extends StatelessWidget {
  final VoidCallback onTap;
  final String lastUpdatedText;

  const _TopWeatherCard({required this.onTap, required this.lastUpdatedText});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 100,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ✅ 배경 이미지 (필터 제거하여 선명하게 표시)
            Positioned.fill(
              child: Image.asset(
                'assets/weather_img/weather_background.png',
                fit: BoxFit.cover,
              ),
            ),

            // ✅ 내용물 구성
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    // ✅ 아이콘에서 팀 색상 제거 (Neutral Black)
                    child: const Icon(
                      Icons.map_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '실시간 날씨 지도',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF365F7C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '전국 구장 날씨 한눈에 확인하기',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF365F7C).withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white,
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

class _WeatherRow extends StatelessWidget {
  final StadiumLoc stadium;
  final StadiumWeather weather;
  final String assetIconPath;
  final VoidCallback onTap;

  const _WeatherRow({
    required this.stadium,
    required this.weather,
    required this.assetIconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              // ✅ 위치 아이콘에서 팀 색상 제거 (Neutral Dark Gray)
              child: const Icon(
                Icons.location_on,
                color: Colors.black38,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stadium.nameKo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stadium.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Image.asset(assetIconPath, width: 32, height: 32),
                const SizedBox(width: 12),
                SizedBox(
                  width: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${weather.temp.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        weather.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: const Center(child: CircularProgressIndicator(color: Colors.grey)),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('다시 시도', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
