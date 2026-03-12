import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ 한국어 로케일(달력 등)
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
      theme: ThemeData(
        fontFamily: 'Pretendard',
        useMaterial3: true,
        primarySwatch: Colors.red,
      ),
      home: const SplashScreen(),
    );
  }
}
