import 'package:flutter/material.dart';
import '../widgets/review_widget.dart';

class SeatOverlayScreen extends StatelessWidget {
  final String stadiumName;
  final String sectionName;
  final String overlayAsset; // 예: assets/overlays/MUNHAK/SKY4.png
  final Color themeColor;

  const SeatOverlayScreen({
    super.key,
    required this.stadiumName,
    required this.sectionName,
    required this.overlayAsset,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(stadiumName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            Text(
              stadiumName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              sectionName,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),

            // ✅ 오버레이 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 260,
                color: const Color(0xFFF2F2F2),
                alignment: Alignment.center,
                child: Image.asset(
                  overlayAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      '오버레이 이미지를 찾을 수 없어요.\n$overlayAsset',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            ReviewWidget(
              category: 'seat', // 👈 핵심! 카테고리를 'seat'으로 설정
              targetId: sectionName, // 👈 타겟을 구역 이름(예: 101구역)으로 설정
              isEmbedded: true, // 스크롤 안에 넣을 거니까 true
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
