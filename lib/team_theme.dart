import 'package:flutter/material.dart';

class TeamTheme {
  final String id;
  final String nameKo;
  final String fullName; // 정식 명칭 (예: KIA 타이거즈)
  final Color primary;
  final String logoPath;

  const TeamTheme({
    required this.id,
    required this.nameKo,
    required this.fullName,
    required this.primary,
    required this.logoPath,
  });
}

const teamThemes = <String, TeamTheme>{
  'lotte': TeamTheme(
    id: 'lotte',
    nameKo: '롯데',
    fullName: '롯데 자이언츠',
    primary: Color(0xFF041E42),
    logoPath: 'assets/team_logo_img/lotte.png',
  ),
  'kia': TeamTheme(
    id: 'kia',
    nameKo: '기아',
    fullName: 'KIA 타이거즈',
    primary: Color(0xFFEA0029),
    logoPath: 'assets/team_logo_img/kia.png',
  ),
  'lg': TeamTheme(
    id: 'lg',
    nameKo: 'LG',
    fullName: 'LG 트윈스',
    primary: Color(0xFFC30452),
    logoPath: 'assets/team_logo_img/lg.png',
  ),
  'ssg': TeamTheme(
    id: 'ssg',
    nameKo: 'SSG',
    fullName: 'SSG 랜더스',
    primary: Color(0xFFCE0E2D),
    logoPath: 'assets/team_logo_img/ssg.png',
  ),
  'doosan': TeamTheme(
    id: 'doosan',
    nameKo: '두산',
    fullName: '두산 베어스',
    primary: Color(0xFF1A1748),
    logoPath: 'assets/team_logo_img/doosan.png',
  ),
  'nc': TeamTheme(
    id: 'nc',
    nameKo: 'NC',
    fullName: 'NC 다이노스',
    primary: Color(0xFF315288),
    logoPath: 'assets/team_logo_img/nc.png',
  ),
  'kiwoom': TeamTheme(
    id: 'kiwoom',
    nameKo: '키움',
    fullName: '키움 히어로즈',
    primary: Color(0xFF570514),
    logoPath: 'assets/team_logo_img/kiwoom.png',
  ),
  'samsung': TeamTheme(
    id: 'samsung',
    nameKo: '삼성',
    fullName: '삼성 라이온즈',
    primary: Color(0xFF074CA1),
    logoPath: 'assets/team_logo_img/samsung.png',
  ),
  'hanwha': TeamTheme(
    id: 'hanwha',
    nameKo: '한화',
    fullName: '한화 이글스',
    primary: Color(0xFFFC4E00),
    logoPath: 'assets/team_logo_img/hanwha.png',
  ),
  'kt': TeamTheme(
    id: 'kt',
    nameKo: 'KT',
    fullName: 'KT 위즈',
    primary: Color(0xFF000000),
    logoPath: 'assets/team_logo_img/kt.png',
  ),
};
