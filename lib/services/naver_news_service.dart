import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/naver_api.dart';
import '../models/naver_news_article.dart';

class NaverNewsService {
  static const _base = 'https://openapi.naver.com/v1/search/news.json';

  static ({List<String> strong, List<String> weak}) _teamKeys(String teamNameOrId) {
    final t = teamNameOrId.toLowerCase();

    if (t.contains('ssg') || t.contains('랜더스') || t.contains('landers')) {
      return (
      strong: ['SSG 랜더스', '랜더스'],
      weak: ['SSG', '인천', '문학', '랜더스필드'],
      );
    }
    if (t.contains('키움') || t.contains('히어로즈') || t.contains('kiwoom')) {
      return (
      strong: ['키움 히어로즈', '키움', '히어로즈'],
      weak: ['고척'],
      );
    }
    if (t == 'kt' || t.contains('위즈') || t.contains('wiz')) {
      return (
      strong: ['KT 위즈', '위즈'],
      weak: ['KT', '수원'],
      );
    }
    if (t.contains('lg') || t.contains('트윈스') || t.contains('twins')) {
      return (
      strong: ['LG 트윈스', '트윈스'],
      weak: ['LG', '잠실'],
      );
    }
    if (t.contains('두산') || t.contains('베어스') || t.contains('doosan')) {
      return (
      strong: ['두산 베어스', '두산', '베어스'],
      weak: ['잠실'],
      );
    }
    if (t.contains('기아') || t.contains('kia') || t.contains('타이거즈')) {
      return (
      strong: ['KIA 타이거즈', '기아 타이거즈', '타이거즈'],
      weak: ['광주', '챔피언스필드'],
      );
    }
    if (t.contains('삼성') || t.contains('라이온즈') || t.contains('samsung')) {
      return (
      strong: ['삼성 라이온즈', '삼성', '라이온즈'],
      weak: ['대구'],
      );
    }
    if (t.contains('nc') || t.contains('다이노스') || t.contains('dinos')) {
      return (
      strong: ['NC 다이노스', '다이노스'],
      weak: ['NC', '창원'],
      );
    }
    if (t.contains('롯데') || t.contains('자이언츠') || t.contains('lotte')) {
      return (
      strong: ['롯데 자이언츠', '롯데', '자이언츠'],
      weak: ['부산', '사직'],
      );
    }
    if (t.contains('한화') || t.contains('이글스') || t.contains('hanwha')) {
      return (
      strong: ['한화 이글스', '한화', '이글스'],
      weak: ['대전'],
      );
    }

    return (strong: [teamNameOrId], weak: const []);
  }

  static List<String> _buildQueries(String teamNameOrId) {
    final t = teamNameOrId.toLowerCase();
    final keys = _teamKeys(teamNameOrId);

    if (t.contains('기아') || t.contains('kia') || t.contains('타이거즈')) {
      return [
        'KIA 타이거즈',
        '기아 타이거즈',
        '타이거즈 프로야구',
        'KIA 타이거즈 KBO',
      ];
    }

    final List<String> queries = [];

    if (keys.strong.isNotEmpty) {
      queries.add(keys.strong.first);
    }

    if (keys.strong.length >= 2) {
      queries.add('${keys.strong[1]} 프로야구');
    }

    if (keys.weak.isNotEmpty) {
      queries.add('${keys.strong.first} ${keys.weak.first}');
    }

    queries.add('${keys.strong.first} KBO');

    final seen = <String>{};
    return queries.where((q) => seen.add(q)).toList();
  }

  static Future<String?> _extractImageFromArticle(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0',
        },
      ).timeout(const Duration(seconds: 2));

      if (res.statusCode != 200) return null;

      final html = res.body;

      final match = RegExp(
        '<meta property="og:image" content="([^"]+)"',
        caseSensitive: false,
      ).firstMatch(html);

      if (match != null) {
        return match.group(1);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<NaverNewsArticle>> _fetchSingleQuery({
    required String query,
    required int start,
    required int display,
    required String sort,
  }) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'query': query,
      'display': display.toString(),
      'start': start.toString(),
      'sort': sort,
    });

    final res = await http.get(
      uri,
      headers: {
        'X-Naver-Client-Id': NaverApiConfig.clientId,
        'X-Naver-Client-Secret': NaverApiConfig.clientSecret,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('네이버 뉴스 실패: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();

    final articles = items.map(NaverNewsArticle.fromJson).toList();

    final result = await Future.wait(
      articles.map((article) async {
        final articleUrl =
        article.originallink.isNotEmpty ? article.originallink : article.link;

        final imageUrl = await _extractImageFromArticle(articleUrl);

        return article.copyWith(imageUrl: imageUrl);
      }),
    );

    return result;
  }

  static Future<List<NaverNewsArticle>> fetchTeamNews({
    required String teamNameOrId,
    int start = 1,
    int display = 5,
    String sort = 'date',
  }) async {
    if (display < 1) display = 1;
    if (display > 100) display = 100;
    if (start < 1) start = 1;
    if (start > 1000) start = 1000;

    final queries = _buildQueries(teamNameOrId);
    final merged = <NaverNewsArticle>[];

    for (final q in queries) {
      try {
        final list = await _fetchSingleQuery(
          query: q,
          start: start,
          display: display,
          sort: sort,
        );
        merged.addAll(list);
      } catch (_) {
        // 한 쿼리 실패해도 전체 실패시키지 않음
      }
    }

    final seen = <String>{};
    final deduped = <NaverNewsArticle>[];

    for (final a in merged) {
      final key = (a.originallink.isNotEmpty ? a.originallink : a.link).trim();
      if (key.isEmpty) continue;
      if (seen.add(key)) deduped.add(a);
    }

    return deduped;
  }
}



