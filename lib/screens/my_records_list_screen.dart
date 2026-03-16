import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'calendar_screen.dart'; // ✅ AddScheduleBottomSheet 사용을 위해 import

class MyRecordsListScreen extends StatefulWidget {
  final String uid;
  final Color themeColor;

  const MyRecordsListScreen({
    super.key,
    required this.uid,
    required this.themeColor,
  });

  @override
  State<MyRecordsListScreen> createState() => _MyRecordsListScreenState();
}

class _MyRecordsListScreenState extends State<MyRecordsListScreen> {
  // ✅ 기록 삭제
  void _deleteRecord(String docId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('기록 삭제'),
            content: const Text('이 직관 기록을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('jikgwan_records')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
      }
    }
  }

  // ✅ 기록 수정 (캘린더의 바텀시트 재사용)
  void _editRecord(Map<String, dynamic> data, String docId) {
    // Firestore Timestamp -> DateTime 변환
    final Timestamp ts = data['date'];
    final DateTime date = ts.toDate();

    // 캘린더 시트에 넘겨줄 포맷으로 데이터 준비
    final eventData = {
      'id': docId,
      'title': data['title'],
      'opponent': data['opponent'],
      'stadium': data['stadium'],
      'result': data['result'],
      'date': date,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddScheduleBottomSheet(
        currentTeamId: data['myTeamId'] ?? '',
        initialDate: date,
        editingEvent: eventData, // 기존 데이터 주입
        onEventAdded: (newData, newDate) async {
          // 수정 로직
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('jikgwan_records')
              .doc(docId)
              .update({...newData, 'date': Timestamp.fromDate(newDate)});
          // 시트가 닫히면 스트림이 알아서 업데이트함
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '나의 직관 기록 모아보기',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('jikgwan_records')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '기록된 직관 경기가 없어요.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              return _buildRecordTile(data, docId);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecordTile(Map<String, dynamic> data, String docId) {
    final Timestamp? ts = data['date'];
    final DateTime date = ts != null ? ts.toDate() : DateTime.now();
    final String dateStr = DateFormat('MM.dd').format(date);

    final String title = data['title'] ?? '';
    final String stadium = data['stadium'] ?? '-';
    final String opponent = data['opponent'] ?? '-';
    final String result = data['result'] ?? '예정';

    Color resultColor = Colors.grey;
    if (result == '승')
      resultColor = const Color(0xFFC62828);
    else if (result == '무')
      resultColor = Colors.green;
    else if (result == '패')
      resultColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                result,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: resultColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // 🌟 수정된 부분: 상대팀 이름에 이미 'vs'가 있으면 그대로 출력, 없으면 'vs ' 붙여서 출력
                  opponent.contains('vs') ? opponent : 'vs $opponent',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$stadium | $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          // ⚙️ 더보기 메뉴 (수정/삭제)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'edit') _editRecord(data, docId);
              if (value == 'delete') _deleteRecord(docId);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('수정')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
