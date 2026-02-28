import 'package:flutter/material.dart';
import '../widgets/review_widget.dart';
import 'dart:convert'; // base64Decode를 위해 필요

class SeatOverlayScreen extends StatelessWidget {
  final String stadiumName;
  final String sectionName;
  final String overlayAsset;
  final String colorHex; // ✅ 추가
  final Color themeColor;

  const SeatOverlayScreen({
    super.key,
    required this.stadiumName,
    required this.sectionName,
    required this.overlayAsset,
    required this.colorHex, // ✅ 추가
    required this.themeColor,
  });

  // ✅ 헥사코드를 Color 객체로 변환하는 유틸리티
  Color _hexToColor(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
            // ✅ 구역 이름과 색상 도트 배치
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _hexToColor(colorHex), // ✅ CSV에서 가져온 색상 적용
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  sectionName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 260,
                color: const Color(0xFFF2F2F2),
                alignment: Alignment.center,
                child: Image.asset(
                  overlayAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            ReviewWidget(
              category: 'seat',
              targetId: sectionName,
              isEmbedded: true,
            ),
          ],
        ),
      ),
    );
  }
}
