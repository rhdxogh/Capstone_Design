import 'package:flutter/material.dart';

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

            // ✅ 아래 텍스트는 "나중에 추가" 예정이라면 일단 비워둠
            const SizedBox(height: 20),
            const Text(
              '좌석안내',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              '※ 아래 안내 문구는 추후 추가 예정',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
