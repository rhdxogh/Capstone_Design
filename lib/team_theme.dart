import 'package:flutter/material.dart';

class TeamTheme {
  final String id; // 'ssg' 같은 string
  final String nameKo; // 'SSG'
  final Color primary;
  final String logoPath; // 로고 이미지 경로

  const TeamTheme({
    required this.id,
    required this.nameKo,
    required this.primary,
    required this.logoPath, // 생성자에 logoPath 추가
  });
}

const teamThemes = <String, TeamTheme>{
  'lotte': TeamTheme(
    id: 'lotte',
    nameKo: '롯데',
    primary: Color(0xFF041E42),
    logoPath: 'assets/team_logo_img/lotte.png',
  ),
  'kia': TeamTheme(
    id: 'kia',
    nameKo: '기아',
    primary: Color(0xFFEA0029),
    logoPath: 'assets/team_logo_img/kia.png',
  ),
  'lg': TeamTheme(
    id: 'lg',
    nameKo: 'LG',
    primary: Color(0xFFC30452),
    logoPath: 'assets/team_logo_img/lg.png',
  ),
  'ssg': TeamTheme(
    id: 'ssg',
    nameKo: 'SSG',
    primary: Color(0xFFCE0E2D),
    logoPath: 'assets/team_logo_img/ssg.png',
  ),
  'doosan': TeamTheme(
    id: 'doosan',
    nameKo: '두산',
    primary: Color(0xFF1A1748),
    logoPath: 'assets/team_logo_img/doosan.png',
  ),
  'nc': TeamTheme(
    id: 'nc',
    nameKo: 'NC',
    primary: Color(0xFF315288),
    logoPath: 'assets/team_logo_img/nc.png',
  ),
  'kiwoom': TeamTheme(
    id: 'kiwoom',
    nameKo: '키움',
    primary: Color(0xFF570514),
    logoPath: 'assets/team_logo_img/kiwoom.png',
  ),
  'samsung': TeamTheme(
    id: 'samsung',
    nameKo: '삼성',
    primary: Color(0xFF074CA1),
    logoPath: 'assets/team_logo_img/samsung.png',
  ),
  'hanwha': TeamTheme(
    id: 'hanwha',
    nameKo: '한화',
    primary: Color(0xFFFC4E00),
    logoPath: 'assets/team_logo_img/hanwha.png',
  ),
  'kt': TeamTheme(
    id: 'kt',
    nameKo: 'KT',
    primary: Color(0xFF000000),
    logoPath: 'assets/team_logo_img/kt.png',
  ),
};
