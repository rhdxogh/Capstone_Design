import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/weather_api.dart';
import '../data/stadium_locations.dart';
import '../models/stadium_weather.dart';

class WeatherService {
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

  static Future<List<StadiumWeather>> fetchAll() async {
    return Future.wait(
      stadiumLocations.map(fetchWeather),
    );
  }
}
