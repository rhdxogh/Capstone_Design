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
        backgroundColor: AppColors.brandRed,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 0.92,
          children: teamThemes.values.map((t) {
            final isSel = selected == t.id;
            return GestureDetector(
              onTap: () => setState(() => selected = t.id),
              child: Card(
                elevation: 0,
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
                      // 로고 이미지는 팀별로 아직 없으니까 텍스트로 대체
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: t.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.sports_baseball, color: t.primary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.nameKo,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
                            fontSize: 12,
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
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selected == null
                    ? Colors.grey
                    : AppColors.brandRed,
                foregroundColor: Colors.white,
              ),
              onPressed: selected == null
                  ? null
                  : () {
                      if (widget.returnSelectedTeamId) {
                        Navigator.pop(context, selected); // ✅ 선택값 반환
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MainShell(uid: 'mock', teamId: selected!),
                          ),
                        );
                      }
                    },

              child: const Text('선택 완료'),
            ),
          ),
        ),
      ),
    );
  }
}
