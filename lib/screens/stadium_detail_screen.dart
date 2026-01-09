import 'package:flutter/material.dart';

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
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(stadiumName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            // ✅ 제목/부제
            Text(
              stadiumName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '구장 정보를 한눈에 확인해보세요.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),

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

            const SizedBox(height: 18),

            const Text(
              '무엇을 도와드릴까요?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // ✅ 좌석정보 / 먹거리정보 / 교통안내 메뉴 카드
            _MenuCard(
              iconPath: 'assets/etc/chair.png',
              title: '좌석정보',
              onTap: () {
                // TODO: 좌석 오버레이 상세 화면 연결
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('좌석정보(다음 단계에서 연결)')),
                );
              },
            ),
            const SizedBox(height: 12),
            _MenuCard(
              iconPath: 'assets/etc/chicken.png',
              title: '먹거리정보',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('먹거리정보(다음 단계에서 연결)')),
                );
              },
            ),
            const SizedBox(height: 12),
            _MenuCard(
              iconPath: 'assets/etc/bus.png',
              title: '교통안내',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('교통안내(다음 단계에서 연결)')),
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
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
          ],
        ),
      ),
    );
  }
}
