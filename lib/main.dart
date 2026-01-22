import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jikgwan_mate/screens/calendar_screen.dart';
import 'package:jikgwan_mate/screens/splash_screen.dart'; // 1. 이 패키지를 임포트하세요.

void main() async {
  // 2. 플러터 엔진과 위젯 바인딩을 먼저 초기화합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 3. 한국어(ko_KR) 로케일 데이터를 초기화합니다.
  await initializeDateFormatting('ko_KR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '직관메이트',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const SplashScreen(), // 메인 홈 화면 연결
    );
  }
}
