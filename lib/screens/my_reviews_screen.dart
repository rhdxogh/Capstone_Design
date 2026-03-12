import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class MyReviewsScreen extends StatefulWidget {
  final String uid;
  final Color themeColor;

  const MyReviewsScreen({
    super.key,
    required this.uid,
    required this.themeColor,
  });

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  // ✅ 삭제 기능
  void _deleteReview(String docId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('리뷰 삭제'),
            content: const Text('이 리뷰를 정말 삭제하시겠습니까?'),
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
          .collection('reviews')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('리뷰가 삭제되었습니다.')));
      }
    }
  }

  // ✅ 수정 기능 (바텀시트 호출)
  void _showEditSheet(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditReviewSheet(
        docId: docId,
        initialData: data,
        themeColor: widget.themeColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '내가 쓴 후기 관리',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('uid', isEqualTo: widget.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('데이터 로드 실패\n${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '아직 작성한 후기가 없어요.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return _buildMyReviewCard(data, docId);
            },
          );
        },
      ),
    );
  }

  Widget _buildMyReviewCard(Map<String, dynamic> data, String docId) {
    final String category = data['category'] == 'food' ? '먹거리' : '좌석';
    final String target = data['targetId'] ?? '-';
    final double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final String content = data['content'] ?? '';
    final String? base64Img = data['imageBase64'];

    final Timestamp? ts = data['createdAt'];
    final String dateStr = ts != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(ts.toDate())
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 카테고리 + 타겟명 + (수정/삭제 버튼)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category == '먹거리'
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: category == '먹거리' ? Colors.orange : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  target,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // ✏️ 수정 버튼
              InkWell(
                onTap: () => _showEditSheet(docId, data),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 8),
              // 🗑️ 삭제 버튼
              InkWell(
                onTap: () => _deleteReview(docId),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '$rating',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (base64Img != null && base64Img.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(base64Img),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          if (content.isNotEmpty)
            Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}

// 🛠️ 리뷰 수정용 바텀시트 (내부 클래스)
class _EditReviewSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;
  final Color themeColor;

  const _EditReviewSheet({
    required this.docId,
    required this.initialData,
    required this.themeColor,
  });

  @override
  State<_EditReviewSheet> createState() => _EditReviewSheetState();
}

class _EditReviewSheetState extends State<_EditReviewSheet> {
  late TextEditingController _ctrl;
  late double _rating;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialData['content'] ?? '');
    _rating = (widget.initialData['rating'] as num?)?.toDouble() ?? 5.0;
    _base64Image = widget.initialData['imageBase64'];
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 50,
    );
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() => _base64Image = base64Encode(bytes));
    }
  }

  Future<void> _update() async {
    setState(() => _isUploading = true);
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.docId)
          .update({
            'content': _ctrl.text,
            'rating': _rating,
            'imageBase64': _base64Image,
            // 'updatedAt': FieldValue.serverTimestamp(), // 필요하면 추가
          });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '리뷰 수정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: _base64Image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(_base64Image!),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt),
                                  Text('사진 변경'),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '별점 수정',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = index + 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '내용 수정',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ctrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: '내용을 입력하세요.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _isUploading ? null : _update,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('수정 완료'),
            ),
          ),
        ],
      ),
    );
  }
}
