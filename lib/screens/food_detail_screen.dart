import 'package:flutter/material.dart';
import 'food_guide_screen.dart';
// ✅ ReviewWidget import 추가
import '../widgets/review_widget.dart';

class FoodDetailScreen extends StatefulWidget {
  final String stadiumId;
  final String stadiumName;
  final Color themeColor;
  final FoodItem food;

  const FoodDetailScreen({
    super.key,
    required this.stadiumId,
    required this.stadiumName,
    required this.themeColor,
    required this.food,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  // 🗑️ 삭제: 기존 임시 데이터(reviews)와 작성 함수(_openWriteReview)는 이제 필요 없습니다.

  @override
  Widget build(BuildContext context) {
    final f = widget.food;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            // --- 기존 매장 정보 영역 (그대로 유지) ---
            Text(
              f.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '위치 : ${f.location} ${f.floor}',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                color: const Color(0xFFF2F2F2),
                alignment: Alignment.center,
                child: Image.asset(
                  f.foodImg,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fastfood, size: 34),
                      const SizedBox(height: 8),
                      Text(
                        '이미지를 찾을 수 없어요.\n${f.foodImg}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ✅ 여기에 ReviewWidget 추가!
            // 기존의 "후기정보" 텍스트, 버튼, _ReviewCard 리스트를 모두 지우고 이거 하나면 끝납니다.
            ReviewWidget(
              category: 'food', // 카테고리: 음식
              targetId: f.name, // 타겟: 매장 이름 (예: 버거킹)
              isEmbedded: true, // 스크롤 안에 넣을 거니까 true
            ),
          ],
        ),
      ),
    );
  }
}

// 🗑️ 삭제: 하단에 있던 FoodReview 클래스, _ReviewCard, _StarsRow, _FoodReviewWriteSheet 등도
// ReviewWidget 파일에 이미 다 있으므로 이 파일에서는 삭제해도 됩니다.
