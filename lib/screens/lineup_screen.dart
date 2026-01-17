import 'package:flutter/material.dart';

class LineupScreen extends StatelessWidget {
  final dynamic game;
  final Color themeColor;

  const LineupScreen({super.key, required this.game, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경을 순수 하얀색으로 설정
      appBar: AppBar(
        title: const Text(
          '오늘의 라인업',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${game['away']} vs ${game['home']}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${game['stadium']} | ${game['time']}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const Text(
              '라인업 정보는 준비 중입니다.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
