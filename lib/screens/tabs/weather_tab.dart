

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

  /// ✅ OpenWeather icon code(01d, 02n...) 또는 description 기반으로
  /// assets/weather_img/ 안의 아이콘으로 매핑
  String _assetIconPath(StadiumWeather w) {
    final icon = (w.icon).toLowerCase(); // ex) 01d, 02n...
    final desc = (w.description).toLowerCase();

    // --- OpenWeather 아이콘 코드 기반(가장 안정적) ---
    // 01d/01n: clear sky
    if (icon.startsWith('01')) return 'assets/weather_img/sun.png';

    // 02d/02n: few clouds
    if (icon.startsWith('02')) return 'assets/weather_img/sunandcloud.png';

    // 03d/03n: scattered clouds, 04d/04n: broken/overcast clouds
    if (icon.startsWith('03') || icon.startsWith('04')) {
      return 'assets/weather_img/cloud.png';
    }

    // 09: shower rain, 10: rain
    if (icon.startsWith('09') || icon.startsWith('10')) {
      return 'assets/weather_img/rain.png';
    }

    // 11: thunderstorm → 지금 assets에 storm이 없으니 rain으로 대체
    if (icon.startsWith('11')) return 'assets/weather_img/rain.png';

    // 13: snow
    if (icon.startsWith('13')) return 'assets/weather_img/snow.png';

    // 50: mist/fog/haze → 지금 fog 아이콘이 없으니 cloud로 대체
    if (icon.startsWith('50')) return 'assets/weather_img/cloud.png';

    // --- 혹시 icon이 비었거나 예상 못한 값일 때 description으로 보정 ---
    if (desc.contains('rain') || desc.contains('비')) return 'assets/weather_img/rain.png';
    if (desc.contains('snow') || desc.contains('눈')) return 'assets/weather_img/snow.png';
    if (desc.contains('cloud') || desc.contains('구름')) return 'assets/weather_img/cloud.png';

    // 기본값: 맑음
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
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              _TopWeatherCard(
                teamColor: widget.teamColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeatherMapScreen(themeColor: widget.teamColor),
                    ),
                  );
                },
                lastUpdatedText: _timeText(_lastUpdated),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '오늘의 구장별 날씨',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    _lastUpdated == null ? '' : '업데이트 ${_timeText(_lastUpdated)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<StadiumWeather>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _LoadingList();
                  }

                  if (snapshot.hasError) {
                    return _ErrorBox(
                      message: '날씨를 불러오지 못했어요.\n${snapshot.error}',
                      onRetry: _refresh,
                      teamColor: widget.teamColor,
                    );
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return _ErrorBox(
                      message: '데이터가 비어있어요. 다시 시도해 주세요.',
                      onRetry: _refresh,
                      teamColor: widget.teamColor,
                    );
                  }

                  list.sort((a, b) => a.stadiumId.compareTo(b.stadiumId));

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade400, width: 1.4),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < list.length; i++) ...[
                          _WeatherRow(
                            teamColor: widget.teamColor,
                            stadium: _findStadium(list[i].stadiumId),
                            weather: list[i],
                            // ✅ 네트워크 대신 asset 아이콘 경로 전달
                            assetIconPath: _assetIconPath(list[i]),
                            onTap: () {
                              final s = _findStadium(list[i].stadiumId);
                              _goDetail(s);
                            },
                          ),
                          if (i != list.length - 1)
                            Divider(height: 1, color: Colors.grey.shade200),
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
  final Color teamColor;
  final VoidCallback onTap;
  final String lastUpdatedText;

  const _TopWeatherCard({
    required this.teamColor,
    required this.onTap,
    required this.lastUpdatedText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias, // ✅ 배경 이미지가 둥근 모서리 밖으로 안 나가게
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: teamColor.withOpacity(0.25)),
        ),
        child: Stack(
          children: [
            // ✅ 배경 이미지
            Positioned.fill(
              child: Image.asset(
                'assets/weather_img/weather_background.png',
                fit: BoxFit.cover,
              ),
            ),

            // ✅ 가독성용 오버레이(필수는 아닌데 훨씬 예쁨)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.55), // 숫자 올리면 더 뿌옇게
              ),
            ),

            // ✅ 기존 내용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '실시간 날씨 보러가기',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '각 구장별 현재 날씨를 확인해요',
                          style: TextStyle(fontSize: 12.5, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.arrow_forward),
                      SizedBox(height: 6),
                      // lastUpdatedText 는 const 제거해야 사용 가능
                      Text(
                        lastUpdatedText.isEmpty ? '' : lastUpdatedText,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
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
  final Color teamColor;
  final StadiumLoc stadium;
  final StadiumWeather weather;
  final String assetIconPath;
  final VoidCallback onTap;

  const _WeatherRow({
    required this.teamColor,
    required this.stadium,
    required this.weather,
    required this.assetIconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tempText = '${weather.temp.toStringAsFixed(0)}°';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: teamColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.place, color: teamColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stadium.nameKo,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stadium.address,
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Image.asset(
                      assetIconPath,
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.cloud, color: teamColor, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56, // 글자 흔들리면 60까지 올려도 됨
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tempText,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        weather.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400, width: 1.4),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('날씨 불러오는 중...'),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color teamColor;

  const _ErrorBox({
    required this.message,
    required this.onRetry,
    required this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: Colors.grey.shade800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: teamColor,
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
    );
  }
}