import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../team_theme.dart';
import 'post_detail_screen.dart';

class MyPostsScreen extends StatelessWidget {
  final String uid;
  final Color themeColor;

  const MyPostsScreen({super.key, required this.uid, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: themeColor,

        foregroundColor: Colors.white,

        elevation: 0,

        title: const Text(
          '내가 쓴 게시글',

          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('오류가 발생했습니다.'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '아직 작성한 게시글이 없습니다.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _MyPostCard(
                postId: doc.id,
                data: data,
                myUid: uid,
                teamColor: themeColor,
              );
            },
          );
        },
      ),
    );
  }
}

// ✅ 내가 쓴 글 목록용 카드 위젯 (수정, 삭제 기능 추가됨)
class _MyPostCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;
  final String myUid;
  final Color teamColor;

  const _MyPostCard({
    required this.postId,
    required this.data,
    required this.myUid,
    required this.teamColor,
  });

  // 📝 게시글 수정 다이얼로그
  void _editPost(BuildContext context, String currentContent) {
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
            style: ElevatedButton.styleFrom(backgroundColor: teamColor),
            onPressed: () async {
              if (editCtrl.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .update({'content': editCtrl.text.trim()});
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('수정완료', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🗑️ 게시글 삭제 로직
  void _deletePost(BuildContext context) async {
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
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = teamThemes[data['teamId']];
    final String teamFullName = team?.fullName ?? 'KBO 팬';
    final String mascotPath = 'assets/mascot_img/${data['teamId']}.png';

    final bool isLiked = (data['likedBy'] ?? []).contains(myUid);
    final bool isDisliked = (data['dislikedBy'] ?? []).contains(myUid);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              postId: postId,
              myUid: myUid,
              teamColor: teamColor,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    mascotPath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 🌟 Expanded로 감싸서 텍스트 영역이 남는 공간을 다 차지하게 함 (쩜쩜쩜 버튼을 우측 끝으로 밀기 위해)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nickname'] ?? '익명',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teamFullName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 🌟 우측 상단 수정/삭제 팝업 메뉴 추가
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit')
                      _editPost(context, data['content'] ?? '');
                    if (value == 'delete') _deletePost(context);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(value: 'edit', child: Text('수정하기')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제하기', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              data['content'] ?? '',
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),

            if (data['imageBase64'] != null &&
                data['imageBase64'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(data['imageBase64']),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 하단 아이콘들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      color: isLiked ? teamColor : Colors.grey.shade500,
                      size: 22,
                    ),
                    if ((data['likeCount'] ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${data['likeCount']}',
                        style: TextStyle(
                          color: isLiked ? teamColor : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      isDisliked
                          ? Icons.thumb_down
                          : Icons.thumb_down_alt_outlined,
                      color: isDisliked ? Colors.red : Colors.grey.shade500,
                      size: 22,
                    ),
                    if ((data['dislikeCount'] ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${data['dislikeCount']}',
                        style: TextStyle(
                          color: isDisliked ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.chat_outlined,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                    if ((data['commentCount'] ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${data['commentCount']}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
