import 'package:flutter/material.dart';

class StadiumTab extends StatelessWidget {
  final Color teamColor;
  const StadiumTab({super.key, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '구장 탭(추후 구현)',
        style: TextStyle(color: teamColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
