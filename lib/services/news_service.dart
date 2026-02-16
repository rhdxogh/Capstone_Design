import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/news_api.dart';
import '../models/news_article.dart';

class NewsService {
  static const _base = 'https://newsapi.org/v2';

  /// 앱에서 쓰는 teamId / 팀명(예: "ssg", "SSG", "한화", "KT", "키움") 등을
  /// 뉴스 검색에 적합한 "정식 구단명 키워드"로 변환
  static String toTeamKeyword(String input) {
    final s = input.trim().toLowerCase();

    // teamThemes.id 기준(예: ssg, hanwha, kt ...)이거나, 한글 팀명 들어와도 최대한 매칭
    if (s == 'ssg' || s.contains('랜더스') || s.contains('ssg')) return 'SSG 랜더스';
    if (s == 'lg' || s.contains('트윈스')) return 'LG 트윈스';
    if (s == 'kt' || s.contains('위즈')) return 'KT 위즈';
    if (s == 'kia' || s.contains('타이거즈')) return 'KIA 타이거즈';
    if (s == 'samsung' || s == 'sam' || s.contains('라이온즈') || s.contains('삼성')) return '삼성 라이온즈';
    if (s == 'lotte' || s.contains('자이언츠') || s.contains('롯데')) return '롯데 자이언츠';
    if (s == 'doosan' || s.contains('베어스') || s.contains('두산')) return '두산 베어스';
    if (s == 'nc' || s.contains('다이노스') || s.contains('엔씨')) return 'NC 다이노스';
    if (s == 'kiwoom' || s.contains('히어로즈') || s.contains('키움')) return '키움 히어로즈';
    if (s == 'hanwha' || s.contains('이글스') || s.contains('한화')) return '한화 이글스';

    // 못 찾으면 원문을 그대로(그래도 팀명 넣으면 동작은 하게)
    return input.trim();
  }

  /// 팀별로 자주 끼는 잡뉴스를 제외 키워드로 제거 (필요하면 더 추가 가능)
  static String _teamNoiseExcludes(String teamKeyword) {
    // 공통 제외어(야구 기사에 거의 필요없는 것들)
    final common = '-정치 -연예 -주식 -코인 -부동산 -IT -게임 -경제';

    // 팀별 추가 제외어
    if (teamKeyword.contains('SSG')) {
      // SSG = 쇼핑몰/회사/닷컴 쪽 섞이는 경우가 많아서 강하게 제외
      return '$common -SSG닷컴 -ssg닷컴 -SSG.COM -신세계 -이마트 -쓱닷컴 -쓱배송';
    }
    return common;
  }

  /// ✅ 팀 키워드로 "구단 소식" 검색
  /// - input은 teamId든 teamNameKo든 아무거나 넣어도 됨 (내부에서 정식명으로 변환)
  static Future<List<NewsArticle>> fetchTeamNews({
    required String teamInput,
    int page = 1,
    int pageSize = 10,
  }) async {
    final teamKeyword = toTeamKeyword(teamInput);
    final excludes = _teamNoiseExcludes(teamKeyword);

    // 핵심: "정식 구단명"을 따옴표로 묶어서 한 덩어리로 검색
    // + 야구 문맥 키워드 같이 넣어서 정확도 높임
    final q = '("$teamKeyword") '
        '(KBO OR 프로야구 OR 야구 OR 한국시리즈 OR 시범경기 OR FA OR 트레이드 OR 부상 OR 선발 OR 1군 OR 2군) '
        '$excludes';

    final uri = Uri.parse('$_base/everything').replace(queryParameters: {
      'q': q,
      'language': 'ko',
      'sortBy': 'publishedAt',
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'apiKey': NewsApiConfig.newsApiKey,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('뉴스 불러오기 실패: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final articles = (data['articles'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NewsArticle.fromNewsApi)
        .where((a) => a.title.trim().isNotEmpty && a.url.trim().isNotEmpty)
        .toList();

    return articles;
  }

  /// ✅ KBO 전체(야구) 뉴스
  static Future<List<NewsArticle>> fetchKboNews({
    int page = 1,
    int pageSize = 10,
  }) async {
    final q = '(KBO OR 프로야구 OR 야구 OR 한국시리즈) '
        '(개막 OR 시범경기 OR 경기 OR 선발 OR 타자 OR 투수 OR 홈런 OR FA OR 트레이드 OR 부상) '
        '-정치 -연예 -주식 -코인 -부동산 -IT -게임 -경제';

    final uri = Uri.parse('$_base/everything').replace(queryParameters: {
      'q': q,
      'language': 'ko',
      'sortBy': 'publishedAt',
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'apiKey': NewsApiConfig.newsApiKey,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('KBO 뉴스 불러오기 실패: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final articles = (data['articles'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NewsArticle.fromNewsApi)
        .where((a) => a.title.trim().isNotEmpty && a.url.trim().isNotEmpty)
        .toList();

    return articles;
  }
}

