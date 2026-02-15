import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ReviewWidget extends StatefulWidget {
  final String category;
  final String targetId;
  final bool isEmbedded;

  const ReviewWidget({
    super.key,
    required this.category,
    required this.targetId,
    this.isEmbedded = false,
  });

  @override
  State<ReviewWidget> createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  final _reviewController = TextEditingController();
  double _rating = 5.0;
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  String? _base64Image;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 50,
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final String base64String = base64Encode(bytes);
      setState(() {
        _pickedImage = image;
        _base64Image = base64String;
      });
    }
  }

  Future<void> _addReview() async {
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    if (_reviewController.text.isEmpty && _base64Image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내용이나 사진을 입력해주세요.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final nickname = userDoc.data()?['nickname'] ?? '익명';

      await FirebaseFirestore.instance.collection('reviews').add({
        'category': widget.category,
        'targetId': widget.targetId,
        'uid': user!.uid,
        'nickname': nickname,
        'rating': _rating,
        'content': _reviewController.text,
        'imageBase64': _base64Image,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _reviewController.clear();
      setState(() {
        _rating = 5.0;
        _pickedImage = null;
        _base64Image = null;
        _isUploading = false;
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
    }
  }

  void _deleteReview(String docId) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(docId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰가 삭제되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  // ✨ 리뉴얼된 리뷰 작성 시트 (디자인 반영)
  void _openWriteReviewSheet() {
    _reviewController.clear();
    _rating = 5.0;
    _pickedImage = null;
    _base64Image = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // ✅ 시트 배경 완전 흰색
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85, // 화면 85% 높이 사용
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 바
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          '후기 작성',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // 밸런스용 빈 공간
                    ],
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📸 1. 사진 등록 박스 (점선 스타일)
                          GestureDetector(
                            onTap: () async {
                              await _pickImage();
                              setModalState(() {});
                            },
                            child: _pickedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_pickedImage!.path),
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF8F9FA,
                                      ), // 아주 연한 회색 배경
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        style: BorderStyle.none,
                                      ), // 점선 효과 대신 깔끔한 배경
                                    ),
                                    child: CustomPaint(
                                      painter: _DashedBorderPainter(
                                        color: Colors.grey.shade400,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            size: 32,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '사진 등록하기',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 30),

                          // ⭐ 2. 별점
                          const Text(
                            '만족도를 평가해주세요.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () =>
                                    setModalState(() => _rating = index + 1.0),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    index < _rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: index < _rating
                                        ? const Color(0xFFFDD835)
                                        : Colors.grey.shade300,
                                    size: 32,
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 30),

                          // 📝 3. 텍스트 입력
                          const Text(
                            '생생한 후기를 남겨주세요.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _reviewController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: '이곳의 좋았던 점이나 아쉬웠던 점을 솔직하게 적어주세요.',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.black54,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // ✅ 등록하기 버튼 (하단 고정)
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _addReview,
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200, // 평소엔 연회색
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ).copyWith(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith((states) {
                                    if (states.contains(MaterialState.disabled))
                                      return Colors.grey.shade100;
                                    // 입력이 있으면 색상 변경 (예: 검정 or 팀컬러)
                                    if (_reviewController.text.isNotEmpty ||
                                        _pickedImage != null) {
                                      return const Color(
                                        0xFF222222,
                                      ); // 활성화 시 진한 회색/검정
                                    }
                                    return const Color(0xFFF0F0F0); // 비활성 (기본)
                                  }),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith((states) {
                                    if (_reviewController.text.isNotEmpty ||
                                        _pickedImage != null) {
                                      return Colors.white;
                                    }
                                    return const Color(0xFF999999);
                                  }),
                            ),
                        child: _isUploading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.grey,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '등록하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✨ 카드형 리뷰 디자인 (유지)
  Widget _buildReviewCard(Map<String, dynamic> data, String docId) {
    final isMyReview = user?.uid == data['uid'];
    final Timestamp? ts = data['createdAt'];
    final dateStr = ts != null
        ? DateFormat('yy.MM.dd').format(ts.toDate())
        : '방금 전';
    final String? base64Str = data['imageBase64'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(0),
      color: Colors.transparent, // 배경 투명 (깔끔하게)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['nickname'] ?? '익명',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${data['rating'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (isMyReview)
                InkWell(
                  onTap: () => _deleteReview(docId),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '삭제',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (base64Str != null && base64Str.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(base64Str),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (data['content'] != null && data['content'].toString().isNotEmpty)
            Text(
              data['content'],
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF333333),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '후기 정보',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: _openWriteReviewSheet,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '새로운 후기 작성하기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('category', isEqualTo: widget.category)
              .where('targetId', isEqualTo: widget.targetId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('잠시 후 다시 시도해주세요.');
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Text(
                  '첫 후기를 남겨주세요!',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              );
            }
            ListView view = ListView.builder(
              shrinkWrap: true,
              physics: widget.isEmbedded
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(
                  docs[index].data() as Map<String, dynamic>,
                  docs[index].id,
                );
              },
            );
            return widget.isEmbedded ? view : Expanded(child: view);
          },
        ),
      ],
    );
  }
}

// 🎨 점선 테두리 그리기용 페인터
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);

    final Path dashPath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
