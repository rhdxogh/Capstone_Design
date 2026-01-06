import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('응원하는 구단을 선택해주세요!'),
        backgroundColor: AppColors.brandRed, //
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 0.75, // 로고와 버튼 비율을 위해 살짝 조정
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
                      // ✅ 수정된 부분: 야구공 아이콘 대신 Image.asset 사용
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white, // 로고 배경은 흰색이 깔끔합니다
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            t.logoPath, // ✅ team_theme.dart의 logoPath 변수 사용
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // 이미지가 없을 때를 대비한 대체 아이콘
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
                        maxLines: 1, // 한 줄 고정
                        overflow: TextOverflow.ellipsis, // 넘치면 '...' 처리
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Follow 버튼 디자인
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
                    : AppColors.brandRed, //
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: selected == null
                  ? null
                  : () {
                if (widget.returnSelectedTeamId) {
                  Navigator.pop(context, selected);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainShell(
                        uid: widget.uid,
                        teamId: selected!,
                      ), // ✅ uid 연결
                    ),
                  );
                }
              },
              child: const Text(
                '선택 완료',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
