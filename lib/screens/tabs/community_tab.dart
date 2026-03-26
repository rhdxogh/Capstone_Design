import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../team_theme.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../post_detail_screen.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? myUid = FirebaseAuth.instance.currentUser?.uid;
  String myTeamId = '';
  String myNickname = '익명';
  String? myProfileBase64;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyInfo();
  }

  Future<void> _loadMyInfo() async {
    if (myUid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .get();
    if (mounted) {
      setState(() {
        myTeamId = doc.data()?['teamId'] ?? '';
        myNickname = doc.data()?['nickname'] ?? '익명';
        myProfileBase64 = doc.data()?['profileImageBase64'];
      });
    }
  }

  // ✅ 글쓰기 바텀 시트 (최신 유저 정보 동기화 로직 추가)
  void _openWriteSheet() {
    final controller = TextEditingController();
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '글쓰기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: '야구팬들과 나누고 싶은 이야기를 적어보세요!',
                    border: InputBorder.none,
                  ),
                ),
                if (selectedImage != null)
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(selectedImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedImage = null),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.image_outlined,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 30,
                          maxWidth: 800,
                          maxHeight: 800,
                        );
                        if (pickedFile != null)
                          setSheetState(
                            () => selectedImage = File(pickedFile.path),
                          );
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            teamThemes[myTeamId]?.primary ?? Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: isUploading
                          ? null
                          : () async {
                              if (controller.text.trim().isEmpty &&
                                  selectedImage == null)
                                return;
                              setSheetState(() => isUploading = true);
                              String base64Image = '';

                              try {
                                if (selectedImage != null) {
                                  final bytes = await selectedImage!
                                      .readAsBytes();
                                  base64Image = base64Encode(bytes);
                                }

                                // 🌟 [핵심 변경점] 글 올리기 직전에 파이어베이스에서 내 최신 정보를 다시 가져옴!
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(myUid)
                                    .get();
                                final userData = userDoc.data() ?? {};
                                final currentTeamId = userData['teamId'] ?? '';
                                final currentNickname =
                                    userData['nickname'] ?? '익명';
                                final currentProfileBase64 =
                                    userData['profileImageBase64'];

                                await FirebaseFirestore.instance
                                    .collection('posts')
                                    .add({
                                      'content': controller.text.trim(),
                                      'imageBase64': base64Image,
                                      'uid': myUid,
                                      'nickname': currentNickname,
                                      'teamId': currentTeamId, // 최신 팀 반영!
                                      'userProfileBase64':
                                          currentProfileBase64, // 최신 프사 반영!
                                      'createdAt': FieldValue.serverTimestamp(),
                                      'likeCount': 0,
                                      'dislikeCount': 0,
                                      'commentCount': 0,
                                    });
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                setSheetState(() => isUploading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('업로드 실패: 다시 시도해주세요.'),
                                  ),
                                );
                              }
                            },
                      child: isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '게시하기',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = teamThemes[myTeamId]?.primary ?? Colors.black;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '커뮤니티',
          style: TextStyle(
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: teamColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '전체 구단'),
            Tab(text: '우리 팀'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPostList(isAll: true), _buildPostList(isAll: false)],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: teamColor,
        onPressed: _openWriteSheet,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildPostList({required bool isAll}) {
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true);
    if (!isAll && myTeamId.isNotEmpty)
      query = query.where('teamId', isEqualTo: myTeamId);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('오류가 발생했습니다.'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const Center(
            child: Text(
              '아직 작성된 글이 없습니다.',
              style: TextStyle(color: Colors.grey),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _PostCard(postId: doc.id, data: data, myUid: myUid);
          },
        );
      },
    );
  }
}

// ✅ 메인 피드용 _PostCard (클릭 시 상세 화면으로 이동하도록 껍데기만 남김)
class _PostCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;
  final String? myUid;

  const _PostCard({
    required this.postId,
    required this.data,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final team = teamThemes[data['teamId']];
    final String teamFullName = team?.fullName ?? 'KBO 팬';
    final Color teamColor = team?.primary ?? Colors.black;

    // 🌟 핵심: 프사 -> 마스코트 순으로 경로 설정
    final String? userProfileBase64 = data['userProfileBase64'];
    final String mascotPath =
        (data['teamId'] != null && data['teamId'].toString().isNotEmpty)
        ? 'assets/mascot_img/${data['teamId']}.png'
        : '';

    final bool isLiked =
        myUid != null && (data['likedBy'] ?? []).contains(myUid);
    final bool isDisliked =
        myUid != null && (data['dislikedBy'] ?? []).contains(myUid);

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
            // 1. 프로필 영역 (🌟 이 부분이 변경됨)
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade200,
                  // 1순위: 사용자 프사, 2순위: 팀 마스코트
                  backgroundImage:
                      userProfileBase64 != null && userProfileBase64.isNotEmpty
                      ? MemoryImage(base64Decode(userProfileBase64))
                            as ImageProvider
                      : (mascotPath.isNotEmpty
                            ? AssetImage(mascotPath) as ImageProvider
                            : null),
                  child:
                      (userProfileBase64 == null ||
                              userProfileBase64.isEmpty) &&
                          mascotPath.isEmpty
                      ? const Icon(
                          Icons.account_circle,
                          size: 50,
                          color: Colors.grey,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['nickname'] ?? '익명',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teamFullName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. 본문 내용
            Text(
              data['content'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
              ),
            ),

            // (이미지가 있다면 미리보기)
            if (data['imageBase64'] != null &&
                data['imageBase64'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(data['imageBase64']),
                  width: double.infinity,
                  height: 180, // 피드에서는 너무 길지 않게 잘라서 보여줌
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 3. 하단 액션 아이콘 (디자인만 유지, 누르면 상세화면으로 넘어감)
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
