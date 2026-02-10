import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class ReviewWidget extends StatefulWidget {
  final String category; // 'food' or 'seat'
  final String targetId; // 가게명 or 구역명
  final bool isEmbedded; // ✅ 추가됨: 스크롤 뷰 안에 넣을 땐 true로 설정

  const ReviewWidget({
    super.key,
    required this.category,
    required this.targetId,
    this.isEmbedded = false, // 기본값은 false (확장형)
  });

  @override
  State<ReviewWidget> createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  final User? user = FirebaseAuth.instance.currentUser;

  void _showWriteReviewSheet() {
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요한 서비스입니다.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewWriteSheet(
        category: widget.category,
        targetId: widget.targetId,
        uid: user!.uid,
      ),
    );
  }

  void _deleteReview(String docId, String writerUid) {
    if (user?.uid != writerUid) return;
    FirebaseFirestore.instance.collection('reviews').doc(docId).delete().then((
      _,
    ) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰가 삭제되었습니다.')));
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 구조 변경: 헤더와 리스트를 상황에 맞게 배치
    Widget listContent = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('category', isEqualTo: widget.category)
          .where('targetId', isEqualTo: widget.targetId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('데이터 로드 오류'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text('첫 번째 후기를 남겨보세요!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        // ✅ isEmbedded가 true면 shrinkWrap 사용 (부모 스크롤 사용)
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          shrinkWrap: widget.isEmbedded,
          physics: widget.isEmbedded
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String docId = docs[index].id;
            final String writerUid = data['writerUid'] ?? '';
            final bool isMyReview = user?.uid == writerUid;
            final Timestamp? ts = data['createdAt'];
            final String dateStr = ts != null
                ? DateFormat('yyyy.MM.dd').format(ts.toDate())
                : '-';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RatingBarIndicator(
                      rating: (data['rating'] ?? 0).toDouble(),
                      itemBuilder: (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 18.0,
                    ),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (isMyReview) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _deleteReview(docId, writerUid),
                            child: const Text(
                              '삭제',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data['content'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '야구팬 ${writerUid.length > 4 ? writerUid.substring(0, 4) : writerUid}***',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            );
          },
        );
      },
    );

    // ✅ 임베디드 모드일 때는 Expanded 없이 반환
    if (widget.isEmbedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(height: 1, thickness: 1),
          listContent, // Expanded 없음
        ],
      );
    }

    // ✅ 일반 모드(탭뷰)일 때는 Expanded 사용
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1, thickness: 1),
        Expanded(child: listContent),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '생생한 후기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: _showWriteReviewSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text(
              '후기 쓰기',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ( _ReviewWriteSheet 클래스는 기존과 동일하므로 생략하거나 그대로 두셔도 됩니다. )
// 아래 코드는 편의를 위해 포함합니다.
class _ReviewWriteSheet extends StatefulWidget {
  final String category;
  final String targetId;
  final String uid;
  const _ReviewWriteSheet({
    required this.category,
    required this.targetId,
    required this.uid,
  });
  @override
  State<_ReviewWriteSheet> createState() => _ReviewWriteSheetState();
}

class _ReviewWriteSheetState extends State<_ReviewWriteSheet> {
  final TextEditingController _contentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  void _submit() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'category': widget.category,
        'targetId': widget.targetId,
        'writerUid': widget.uid,
        'content': _contentController.text.trim(),
        'rating': _rating,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 30,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '후기 남기기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '이곳의 좋았던 점이나 아쉬웠던 점을 솔직하게 적어주세요.',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '등록하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
