import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/weather_api.dart';
import '../data/stadium_locations.dart';
import '../models/stadium_weather.dart';

/// ✅ 3시간 간격 예보 1개 포인트(금일/주간 화면에서 사용)
class ForecastPoint {
  final DateTime time;
  final double temp;
  final String description;
  final String icon; // ex) "10d"

  ForecastPoint({
    required this.time,
    required this.temp,
    required this.description,
    required this.icon,
  });
}

class WeatherService {
  /// ✅ 현재 날씨 (기존)
  static Future<StadiumWeather> fetchWeather(StadiumLoc stadium) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
          '?lat=${stadium.lat}'
          '&lon=${stadium.lon}'
          '&appid=${WeatherApiConfig.openWeatherKey}'
          '&units=metric'
          '&lang=kr',
    );

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('날씨 불러오기 실패 (${stadium.nameKo})');
    }

    final data = jsonDecode(res.body);

    return StadiumWeather(
      stadiumId: stadium.id,
      temp: (data['main']['temp'] as num).toDouble(),
      description: data['weather'][0]['description'],
      icon: data['weather'][0]['icon'],
    );
  }

  /// ✅ 모든 구장 현재 날씨 (기존)
  static Future<List<StadiumWeather>> fetchAll() async {
    return Future.wait(
      stadiumLocations.map(fetchWeather),
    );
  }

  /// ✅ 3시간 간격 5일 예보 (추가)
  static Future<List<ForecastPoint>> fetchForecast(StadiumLoc stadium) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast'
          '?lat=${stadium.lat}'
          '&lon=${stadium.lon}'
          '&appid=${WeatherApiConfig.openWeatherKey}'
          '&units=metric'
          '&lang=kr',
    );

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('예보 불러오기 실패 (${stadium.nameKo})');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (json['list'] as List).cast<Map<String, dynamic>>();

    return list.map((e) {
      final dt = DateTime.fromMillisecondsSinceEpoch((e['dt'] as int) * 1000);
      final main = e['main'] as Map<String, dynamic>;
      final weather0 = (e['weather'] as List).first as Map<String, dynamic>;

      return ForecastPoint(
        time: dt,
        temp: (main['temp'] as num).toDouble(),
        description: (weather0['description'] ?? '').toString(),
        icon: (weather0['icon'] ?? '').toString(),
      );
    }).toList();
  }
}
