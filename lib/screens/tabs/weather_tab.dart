import 'package:flutter/material.dart';

class WeatherTab extends StatelessWidget {
  final Color teamColor;
  const WeatherTab({super.key, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '날씨 탭(추후 구현)',
        style: TextStyle(color: teamColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
