import 'package:flutter/material.dart';

class TeamTheme {
  final String id; // 'ssg' 같은 string
  final String nameKo; // 'SSG'
  final Color primary;
  const TeamTheme({
    required this.id,
    required this.nameKo,
    required this.primary,
  });
}

const teamThemes = <String, TeamTheme>{
  'lotte': TeamTheme(id: 'lotte', nameKo: '롯데', primary: Color(0xFF041E42)),
  'kia': TeamTheme(id: 'kia', nameKo: '기아', primary: Color(0xFFEA0029)),
  'lg': TeamTheme(id: 'lg', nameKo: 'LG', primary: Color(0xFFC30452)),
  'ssg': TeamTheme(id: 'ssg', nameKo: 'SSG', primary: Color(0xFFCE0E2D)),
  'doosan': TeamTheme(id: 'doosan', nameKo: '두산', primary: Color(0xFF1A1748)),
  'nc': TeamTheme(id: 'nc', nameKo: 'NC', primary: Color(0xFF315288)),
  'kiwoom': TeamTheme(id: 'kiwoom', nameKo: '키움', primary: Color(0xFF570514)),
  'samsung': TeamTheme(id: 'samsung', nameKo: '삼성', primary: Color(0xFF074CA1)),
  'hanwha': TeamTheme(id: 'hanwha', nameKo: '한화', primary: Color(0xFFFC4E00)),
  'kt': TeamTheme(
    id: 'kt',
    nameKo: 'KT',
    primary: Color(0xFF000000),
  ), // 00000 -> 000000 보정
};
