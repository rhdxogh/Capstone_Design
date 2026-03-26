import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 파이어베이스 임포트 추가!
import '../team_theme.dart';
import '../app_colors.dart';
import 'main_shell.dart';

class TeamSelectScreen extends StatefulWidget {
  final String uid;
  final bool returnSelectedTeamId;
  const TeamSelectScreen({
    super.key,
    required this.uid,
    this.returnSelectedTeamId = false,
  });

  @override
  State<TeamSelectScreen> createState() => _TeamSelectScreenState();
}

class _TeamSelectScreenState extends State<TeamSelectScreen> {
  String? selected;
  bool _isLoading = false; // 🌟 로딩 상태 추가

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '응원하는 구단을 선택해주세요!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.brandRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: teamThemes.values.map((t) {
            final isSel = selected == t.id;
            return GestureDetector(
              onTap: () => setState(() => selected = t.id),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSel ? t.primary : Colors.grey.shade300,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            t.logoPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.sports_baseball,
                                color: t.primary,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.nameKo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSel ? t.primary : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: t.primary),
                        ),
                        child: Text(
                          isSel ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: isSel ? Colors.white : t.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selected == null
                    ? Colors.grey
                    : AppColors.brandRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // 🌟 버튼 누를 때 DB에 저장하는 로직으로 전면 수정
              onPressed: (selected == null || _isLoading)
                  ? null
                  : () async {
                      if (widget.returnSelectedTeamId) {
                        Navigator.pop(context, selected);
                      } else {
                        setState(() => _isLoading = true);
                        try {
                          // 🌟 파이어베이스에 팀 정보 확실하게 저장!!
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.uid)
                              .set({
                                'teamId': selected!,
                              }, SetOptions(merge: true));

                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MainShell(uid: widget.uid, teamId: selected!),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
                          );
                          setState(() => _isLoading = false);
                        }
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '선택 완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
