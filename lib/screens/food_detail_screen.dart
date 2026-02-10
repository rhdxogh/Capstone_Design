import 'package:flutter/material.dart';
import 'food_guide_screen.dart'; // FoodItem 재사용(같은 파일에 모델이 있으면)

class FoodDetailScreen extends StatefulWidget {
  final String stadiumId; // 'munhak' 같은 id (너 스타일에 맞춰)
  final String stadiumName; // '인천 SSG 랜더스 필드'
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
  // ✅ 로컬 후기 (나중에 Firebase로 교체)
  final List<FoodReview> reviews = [
    FoodReview(
      nickname: '열혈야구팬',
      stars: 4.5,
      body: '직관하면서 먹기 딱 좋아요!\n양도 괜찮고 줄이 생각보다 빨리 줄어요.',
      photoAsset: null, // 나중에 리뷰 사진 추가할 때
      createdAt: DateTime.now(),
    ),
    FoodReview(
      nickname: '열혈야구팬2',
      stars: 4.0,
      body: '치킨이 바삭하고 맥주랑 잘 어울립니다.\n다만 가격은 조금 있는 편…',
      photoAsset: null,
      createdAt: DateTime.now(),
    ),
  ];

  void _openWriteReview() async {
    final result = await showModalBottomSheet<FoodReview>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _FoodReviewWriteSheet(themeColor: widget.themeColor),
    );

    if (result != null) {
      setState(() => reviews.insert(0, result));
    }
  }

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
            // ✅ 타이틀/위치
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

            // ✅ 매장 이미지 크게
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

            const SizedBox(height: 18),

            // ✅ 후기 헤더 + 버튼
            Row(
              children: [
                const Text(
                  '후기정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onPressed: _openWriteReview,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text(
                    '이 구역에 후기 등록하기',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ✅ 후기 리스트
            ...reviews.map(
              (r) => _ReviewCard(review: r, themeColor: widget.themeColor),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodReview {
  final String nickname;
  final double stars; // 0~5
  final String body;
  final String? photoAsset; // 나중에 리뷰 사진(assets) 테스트용
  final DateTime createdAt;

  FoodReview({
    required this.nickname,
    required this.stars,
    required this.body,
    required this.photoAsset,
    required this.createdAt,
  });
}

class _ReviewCard extends StatelessWidget {
  final FoodReview review;
  final Color themeColor;

  const _ReviewCard({required this.review, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.nickname,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StarsRow(value: review.stars, color: themeColor),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  review.body,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),

          // 우측(옵션) 사진
          if (review.photoAsset != null) ...[
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                review.photoAsset!,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final double value; // 0~5
  final Color color;

  const _StarsRow({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    // 간단 표시(반별은 아이콘으로는 어렵지만 텍스트로라도)
    final full = value.floor();
    final half = (value - full) >= 0.5;

    return Row(
      children: [
        for (int i = 0; i < full; i++) Icon(Icons.star, size: 16, color: color),
        if (half) Icon(Icons.star_half, size: 16, color: color),
        for (int i = 0; i < (5 - full - (half ? 1 : 0)); i++)
          Icon(Icons.star_border, size: 16, color: color),
      ],
    );
  }
}

/// ✅ 후기 작성 바텀시트
class _FoodReviewWriteSheet extends StatefulWidget {
  final Color themeColor;
  const _FoodReviewWriteSheet({required this.themeColor});

  @override
  State<_FoodReviewWriteSheet> createState() => _FoodReviewWriteSheetState();
}

class _FoodReviewWriteSheetState extends State<_FoodReviewWriteSheet> {
  final nickCtrl = TextEditingController(text: '열혈야구팬');
  final bodyCtrl = TextEditingController();
  double stars = 5.0;

  @override
  void dispose() {
    nickCtrl.dispose();
    bodyCtrl.dispose();
    super.dispose();
  }

  void submit() {
    final nick = nickCtrl.text.trim();
    final body = bodyCtrl.text.trim();

    if (nick.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('닉네임과 내용을 입력해주세요.')));
      return;
    }

    Navigator.pop(
      context,
      FoodReview(
        nickname: nick,
        stars: stars,
        body: body,
        photoAsset: null,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '후기 작성',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Text(
            '닉네임',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: nickCtrl,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            '별점',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          Slider(
            value: stars,
            min: 0,
            max: 5,
            divisions: 10,
            label: stars.toStringAsFixed(1),
            onChanged: (v) => setState(() => stars = v),
            activeColor: widget.themeColor,
          ),

          const SizedBox(height: 6),
          const Text(
            '내용',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: bodyCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '후기를 입력해주세요.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: submit,
              child: const Text(
                '등록하기',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
