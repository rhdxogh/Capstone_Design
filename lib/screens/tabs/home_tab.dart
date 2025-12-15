import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  final String uid;
  final Color teamColor;
  const HomeTab({super.key, required this.uid, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _todayCard(),
        const SizedBox(height: 14),
        const Text('타구단 경기', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _smallRow(),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('구단 소식', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('See More')),
          ],
        ),
        _newsCard(),
      ],
    );
  }

  Widget _todayCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: teamColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Today',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'SSG  VS  KIA',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('18:30', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _smallRow() {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              children: [
                Text('VS', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text(
                  '18:30',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _newsCard() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: const Center(child: Text('뉴스 카드(추후 API 연동)')),
    );
  }
}
