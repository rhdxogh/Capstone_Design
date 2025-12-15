import 'package:flutter/material.dart';
import 'screens/auth_entry_screen.dart';

void main() {
  runApp(const JikgwanMateMockApp());
}

class JikgwanMateMockApp extends StatelessWidget {
  const JikgwanMateMockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthEntryScreen(), // 🔥 여기서 바로 시작
    );
  }
}
