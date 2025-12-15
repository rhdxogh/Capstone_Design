import 'package:flutter/material.dart';
import '../../team_theme.dart';
import '../team_select_screen.dart';

class MyTab extends StatelessWidget {
  final String uid;
  final Color teamColor;
  final String currentTeamId;
  final ValueChanged<String> onTeamChanged;

  const MyTab({
    super.key,
    required this.uid,
    required this.teamColor,
    required this.currentTeamId,
    required this.onTeamChanged,
  });

  @override
  Widget build(BuildContext context) {
    final teamName = teamThemes[currentTeamId]?.nameKo ?? '-';

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '닉네임(시안)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                '@username(시안)',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Text(
                '응원팀: $teamName',
                style: TextStyle(color: teamColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: Icon(Icons.swap_horiz, color: teamColor),
          title: const Text('응원팀 변경'),
          onTap: () async {
            final selected = await Navigator.push<String?>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TeamSelectScreen(uid: uid, returnSelectedTeamId: true),
              ),
            );
            if (selected != null) onTeamChanged(selected);
          },
        ),
      ],
    );
  }
}
