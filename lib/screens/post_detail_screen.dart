import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../team_theme.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String? myUid;
  final Color teamColor;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.myUid,
    required this.teamColor,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();

  // 👍 좋아요 토글 로직
  Future<void> _toggleLike() async {
    if (widget.myUid == null) return;
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      // 데이터 타입 명확히 지정 (에러 방지)
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      List<dynamic> likedBy = data['likedBy'] ?? [];
      List<dynamic> dislikedBy = data['dislikedBy'] ?? [];

      if (likedBy.contains(widget.myUid)) {
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayRemove([widget.myUid]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        Map<String, dynamic> updates = {
          'likedBy': FieldValue.arrayUnion([widget.myUid]),
          'likeCount': FieldValue.increment(1),
        };
        if (dislikedBy.contains(widget.myUid)) {
          updates['dislikedBy'] = FieldValue.arrayRemove([widget.myUid]);
          updates['dislikeCount'] = FieldValue.increment(-1);
        }
        transaction.update(postRef, updates);
      }
    });
  }

  // 👎 싫어요 토글 로직
  Future<void> _toggleDislike() async {
    if (widget.myUid == null) return;
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      List<dynamic> likedBy = data['likedBy'] ?? [];
      List<dynamic> dislikedBy = data['dislikedBy'] ?? [];

      if (dislikedBy.contains(widget.myUid)) {
        transaction.update(postRef, {
          'dislikedBy': FieldValue.arrayRemove([widget.myUid]),
          'dislikeCount': FieldValue.increment(-1),
        });
      } else {
        Map<String, dynamic> updates = {
          'dislikedBy': FieldValue.arrayUnion([widget.myUid]),
          'dislikeCount': FieldValue.increment(1),
        };
        if (likedBy.contains(widget.myUid)) {
          updates['likedBy'] = FieldValue.arrayRemove([widget.myUid]);
          updates['likeCount'] = FieldValue.increment(-1);
        }
        transaction.update(postRef, updates);
      }
    });
  }

  // 💬 댓글 등록 로직
  Future<void> _addComment() async {
    if (_commentCtrl.text.trim().isEmpty || widget.myUid == null) return;
    final text = _commentCtrl.text.trim();
    _commentCtrl.clear();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.myUid)
        .get();
    final nickname = userDoc.data()?['nickname'] ?? '익명';
    final teamId = userDoc.data()?['teamId'] ?? 'ssg';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
          'uid': widget.myUid,
          'nickname': nickname,
          'teamId': teamId,
          'content': text,
          'createdAt': FieldValue.serverTimestamp(),
        });
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'commentCount': FieldValue.increment(1)});
  }

  // 📝 게시글 수정 다이얼로그
  void _editPost(String currentContent) {
    final editCtrl = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 수정'),
        content: TextField(
          controller: editCtrl,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.teamColor),
            onPressed: () async {
              if (editCtrl.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .update({'content': editCtrl.text.trim()});
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('수정완료', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🗑️ 게시글 삭제 로직
  void _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: const Text('게시글을 삭제하면 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  // 📝 댓글 수정/삭제 다이얼로그
  void _showCommentOptions(String commentId, String currentContent) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('댓글 수정'),
              onTap: () {
                Navigator.pop(context);
                _editComment(commentId, currentContent);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('댓글 삭제', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .doc(commentId)
                    .delete();
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .update({'commentCount': FieldValue.increment(-1)});
              },
            ),
          ],
        ),
      ),
    );
  }

  // 📝 댓글 수정 다이얼로그
  void _editComment(String commentId, String currentContent) {
    final editCtrl = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(
          controller: editCtrl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.teamColor),
            onPressed: () async {
              if (editCtrl.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .doc(commentId)
                    .update({'content': editCtrl.text.trim()});
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('수정완료', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          '게시물',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 1. 게시글 본문 영역
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.postId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text('게시글이 삭제되었거나 찾을 수 없습니다.'),
                            ),
                          );
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final team = teamThemes[data['teamId']];
                        final String mascotPath =
                            'assets/mascot_img/${data['teamId']}.png';
                        final bool isLiked =
                            widget.myUid != null &&
                            (data['likedBy'] ?? []).contains(widget.myUid);
                        final bool isDisliked =
                            widget.myUid != null &&
                            (data['dislikedBy'] ?? []).contains(widget.myUid);
                        final bool isMyPost =
                            widget.myUid != null && data['uid'] == widget.myUid;

                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      mascotPath,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.account_circle,
                                        size: 44,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['nickname'] ?? '익명',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          team?.fullName ?? 'KBO 팬',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isMyPost)
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit')
                                          _editPost(data['content'] ?? '');
                                        if (value == 'delete') _deletePost();
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('수정하기'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            '삭제하기',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Text(
                                data['content'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),

                              if (data['imageBase64'] != null &&
                                  data['imageBase64']
                                      .toString()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    base64Decode(data['imageBase64']),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),
                              const Divider(height: 1),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  TextButton.icon(
                                    onPressed: _toggleLike,
                                    icon: Icon(
                                      isLiked
                                          ? Icons.thumb_up
                                          : Icons.thumb_up_alt_outlined,
                                      color: isLiked
                                          ? widget.teamColor
                                          : Colors.grey,
                                    ),
                                    label: Text(
                                      '${data['likeCount'] ?? 0}',
                                      style: TextStyle(
                                        color: isLiked
                                            ? widget.teamColor
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _toggleDislike,
                                    icon: Icon(
                                      isDisliked
                                          ? Icons.thumb_down
                                          : Icons.thumb_down_alt_outlined,
                                      color: isDisliked
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    label: Text(
                                      '${data['dislikeCount'] ?? 0}',
                                      style: TextStyle(
                                        color: isDisliked
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.grey,
                                    ),
                                    label: Text(
                                      '${data['commentCount'] ?? 0}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 1),
                            ],
                          ),
                        );
                      },
                    ),

                    // 2. 댓글 리스트 영역
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.postId)
                          .collection('comments')
                          .orderBy('createdAt', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final commentId = docs[index].id;
                            final cData =
                                docs[index].data() as Map<String, dynamic>;
                            final bool isMyComment =
                                widget.myUid != null &&
                                cData['uid'] == widget.myUid;

                            final commentTeamId = cData['teamId'] ?? 'ssg';
                            final commentTeam = teamThemes[commentTeamId];
                            final String commentMascotPath =
                                'assets/mascot_img/$commentTeamId.png';

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      commentMascotPath,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.account_circle,
                                        size: 36,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              cData['nickname'] ?? '익명',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              commentTeam?.fullName ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          cData['content'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isMyComment)
                                    InkWell(
                                      onTap: () => _showCommentOptions(
                                        commentId,
                                        cData['content'] ?? '',
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 3. 하단 댓글 입력창
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: '댓글을 남겨주세요...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _addComment,
                    borderRadius: BorderRadius.circular(24),
                    child: CircleAvatar(
                      backgroundColor: widget.teamColor,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
