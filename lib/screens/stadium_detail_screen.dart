import 'package:flutter/material.dart';
import 'seat_guide_screen.dart'; // ✅ 좌석안내 화면 import (경로는 파일 위치에 맞게 수정)
import 'food_guide_screen.dart';
import 'traffic_guide_screen.dart';

class StadiumDetailScreen extends StatelessWidget {
  /// 예: 'munhak', 'jamsil', 'gocheok' ...
  final String stadiumId;

  /// 예: '인천 SSG 랜더스 필드'
  final String stadiumName;

  /// 상단바/테마 색
  final Color themeColor;

  const StadiumDetailScreen({
    super.key,
    required this.stadiumId,
    required this.stadiumName,
    required this.themeColor,
  });

  String get viewImagePath => 'assets/view_img/${stadiumId}_view.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        // ✅ 1. 앱 바 타이틀을 중앙으로 정렬하고, 글씨를 살짝 두껍게 처리합니다.
        centerTitle: true,
        title: Text(
          stadiumName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            // ✅ 구장 뷰 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 180,
                color: const Color(0xFFF2F2F2),
                alignment: Alignment.center,
                child: Image.asset(
                  viewImagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      '이미지를 찾을 수 없어요.\n$viewImagePath',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              '무엇을 도와드릴까요?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),

            // ✅ 좌석정보 / 먹거리정보 / 교통안내 메뉴 카드
            _MenuCard(
              iconPath: 'assets/etc/chair.png',
              title: '좌석정보',
              onTap: () {
                // ✅ 여기서 SeatGuideScreen으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeatGuideScreen(
                      stadiumId: stadiumId,
                      stadiumName: stadiumName,
                      themeColor: themeColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            if (stadiumId.toLowerCase() != 'ulsan')
              _MenuCard(
                iconPath: 'assets/etc/chicken.png',
                title: '먹거리정보',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FoodGuideScreen(
                        stadiumId: stadiumId,
                        stadiumName: stadiumName,
                        themeColor: themeColor,
                      ),
                    ),
                  );
                },
              ),


            const SizedBox(height: 12),

            _MenuCard(
              iconPath: 'assets/etc/bus.png',
              title: '교통안내',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrafficGuideScreen(
                      stadiumId: stadiumId,
                      stadiumName: stadiumName,
                      themeColor: themeColor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback onTap;

  const _MenuCard({
    required this.iconPath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            // 아이콘 박스
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                iconPath,
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
