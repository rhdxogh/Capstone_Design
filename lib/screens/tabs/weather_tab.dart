import 'package:flutter/material.dart';

import '../../data/stadium_locations.dart';
import '../../models/stadium_weather.dart';
import '../../services/weather_service.dart';

// ✅ 추가: 상세 페이지로 이동
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

  String _iconUrl(String icon) {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }

  /// ✅ 공통: 상세 화면 이동 함수 (오타/중복 방지용)
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
              // ✅ 상단 카드: 이제 "상세페이지로 이동"
              _TopWeatherCard(
                teamColor: widget.teamColor,
                // 카드 눌렀을 때: (예시로) munhak으로 이동
                onTap: () {
                  final s = stadiumLocations.firstWhere((e) => e.id == 'munhak');
                  _goDetail(s);
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
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < list.length; i++) ...[
                          _WeatherRow(
                            teamColor: widget.teamColor,
                            stadium: _findStadium(list[i].stadiumId),
                            weather: list[i],
                            iconUrl: _iconUrl(list[i].icon),

                            // ✅ row 누르면 해당 구장 상세로 이동
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              teamColor.withOpacity(0.15),
              teamColor.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: teamColor.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: teamColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.cloud, color: teamColor),
            ),
            const SizedBox(width: 12),
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
                Icon(Icons.arrow_forward, color: teamColor),
                const SizedBox(height: 6),
                Text(
                  lastUpdatedText.isEmpty ? '' : lastUpdatedText,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
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
  final String iconUrl;
  final VoidCallback onTap;

  const _WeatherRow({
    required this.teamColor,
    required this.stadium,
    required this.weather,
    required this.iconUrl,
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
              children: [
                Image.network(
                  iconUrl,
                  width: 34,
                  height: 34,
                  errorBuilder: (_, __, ___) => Icon(Icons.cloud, color: teamColor),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tempText,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      weather.description,
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
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
        border: Border.all(color: Colors.grey.shade200),
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
        border: Border.all(color: Colors.grey.shade200),
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


