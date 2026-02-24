import 'package:flutter/material.dart';
import '../data/stadium_locations.dart';
import '../services/weather_service.dart';

class WeatherDetailScreen extends StatefulWidget {
  final StadiumLoc stadium;
  final String stadiumName;
  final Color themeColor;

  const WeatherDetailScreen({
    super.key,
    required this.stadium,
    required this.stadiumName,
    required this.themeColor,
  });

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  late Future<List<ForecastPoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = WeatherService.fetchForecast(widget.stadium);
  }

  // --- helpers ---
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _weekdayKo(int weekday) {
    const w = ['월', '화', '수', '목', '금', '토', '일'];
    return w[weekday - 1];
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour;
    final ap = h < 12 ? '오전' : '오후';
    final hh = h % 12 == 0 ? 12 : h % 12;
    return '$ap ${hh}시';
  }

  /// ✅ ForecastPoint.icon (예: 01d, 02n...) -> assets/weather_img 아이콘 매핑
  String _assetIconPathFromCode(String iconCode) {
    final icon = iconCode.toLowerCase();

    if (icon.startsWith('01')) return 'assets/weather_img/sun.png';
    if (icon.startsWith('02')) return 'assets/weather_img/sunandcloud.png';
    if (icon.startsWith('03') || icon.startsWith('04')) return 'assets/weather_img/cloud.png';
    if (icon.startsWith('09') || icon.startsWith('10')) return 'assets/weather_img/rain.png';
    if (icon.startsWith('11')) return 'assets/weather_img/rain.png'; // thunderstorm 대체
    if (icon.startsWith('13')) return 'assets/weather_img/snow.png';
    if (icon.startsWith('50')) return 'assets/weather_img/cloud.png'; // mist/fog 대체

    return 'assets/weather_img/sun.png';
  }

  // 오늘(금일) 3시간 간격 몇 개만 보여줄 리스트
  List<ForecastPoint> _todaySlots(List<ForecastPoint> all) {
    final now = DateTime.now();
    final today = _dateOnly(now);

    final candidates = all
        .where((p) => _dateOnly(p.time) == today)
        .where((p) => p.time.isAfter(now.subtract(const Duration(minutes: 1))))
        .toList();

    if (candidates.length < 3) {
      final fallback = all.where((p) => _dateOnly(p.time) == today).toList();
      return fallback.take(6).toList();
    }
    return candidates.take(6).toList();
  }

  // 주간(대략) = 날짜별로 그룹핑해서 min/max + 대표 icon/desc
  List<_DailySummary> _dailySummaries(List<ForecastPoint> all) {
    final map = <DateTime, List<ForecastPoint>>{};
    for (final p in all) {
      final key = _dateOnly(p.time);
      map.putIfAbsent(key, () => []).add(p);
    }

    final keys = map.keys.toList()..sort();
    final result = <_DailySummary>[];

    for (final day in keys) {
      final items = map[day]!..sort((a, b) => a.time.compareTo(b.time));

      double minT = items.first.temp;
      double maxT = items.first.temp;
      for (final it in items) {
        if (it.temp < minT) minT = it.temp;
        if (it.temp > maxT) maxT = it.temp;
      }

      // 대표값: 12:00에 가장 가까운 forecast를 대표로 선택(없으면 첫번째)
      ForecastPoint rep = items.first;
      int best = 9999;
      for (final it in items) {
        final diff = (it.time.hour - 12).abs();
        if (diff < best) {
          best = diff;
          rep = it;
        }
      }

      result.add(_DailySummary(
        date: day,
        minTemp: minT,
        maxTemp: maxT,
        icon: rep.icon,
        description: rep.description,
      ));
    }

    return result.take(7).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.stadiumName),
      ),
      body: SafeArea(
        child: FutureBuilder<List<ForecastPoint>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('에러: ${snap.error}'),
                ),
              );
            }

            final all = snap.data ?? [];
            if (all.isEmpty) {
              return const Center(child: Text('예보 데이터가 없어요.'));
            }

            final todaySlots = _todaySlots(all);
            final daily = _dailySummaries(all);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
              children: [
                // ====== 금일 섹션 ======
                const Text(
                  '금일 날씨',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 116,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: todaySlots.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final p = todaySlots[i];
                      return _TodayCard(
                        timeText: _timeLabel(p.time),
                        assetIconPath: _assetIconPathFromCode(p.icon),
                        tempText: '${p.temp.round()}°',
                        tintColor: widget.themeColor,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // ====== 주간 섹션 ======
                Row(
                  children: [
                    const Text(
                      '주간 날씨',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      'forecast 기반(대략)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < daily.length; i++) ...[
                        _DailyRow(
                          themeColor: widget.themeColor,
                          summary: daily[i],
                          weekdayKo: _weekdayKo(daily[i].date.weekday),
                          assetIconPath: _assetIconPathFromCode(daily[i].icon),
                        ),
                        if (i != daily.length - 1)
                          Divider(height: 1, color: Colors.grey.shade200),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  '※ OpenWeather 무료 예보는 3시간 간격/최대 5일치라, 7일은 “가능한 만큼”만 표시돼요.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ===== 아래는 위젯들 =====

class _TodayCard extends StatelessWidget {
  final String timeText;
  final String assetIconPath;
  final String tempText;
  final Color tintColor;

  const _TodayCard({
    required this.timeText,
    required this.assetIconPath,
    required this.tempText,
    required this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Image.asset(
            assetIconPath,
            width: 44,
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.cloud, size: 34, color: tintColor),
          ),
          const SizedBox(height: 4),
          Text(
            tempText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DailySummary {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String icon;
  final String description;

  const _DailySummary({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.icon,
    required this.description,
  });
}

class _DailyRow extends StatelessWidget {
  final Color themeColor;
  final _DailySummary summary;
  final String weekdayKo;
  final String assetIconPath;

  const _DailyRow({
    required this.themeColor,
    required this.summary,
    required this.weekdayKo,
    required this.assetIconPath,
  });

  @override
  Widget build(BuildContext context) {
    final mm = summary.date.month.toString().padLeft(2, '0');
    final dd = summary.date.day.toString().padLeft(2, '0');

    final minT = summary.minTemp.round();
    final maxT = summary.maxTemp.round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$mm/$dd ($weekdayKo)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  summary.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          Image.asset(
            assetIconPath,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.cloud, color: themeColor),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$minT°',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 8),
                Text(
                  '$maxT°',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}