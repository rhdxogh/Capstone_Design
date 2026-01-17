import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  final String teamName;
  final Color themeColor;

  const NewsScreen({
    super.key,
    required this.teamName,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '$teamName 소식',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 10, // 임시 데이터 개수
        separatorBuilder: (_, __) => const Divider(height: 30),
        itemBuilder: (context, index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[뉴스] $teamName, 이번 시즌 각오가 남다르다',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2026.01.18 | 스포츠뉴스',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}
