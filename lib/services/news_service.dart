import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/news_api.dart';
import '../models/news_article.dart';

class NewsService {
  static const _base = 'https://newsapi.org/v2';

  /// 팀 키워드로 뉴스 검색
  /// - teamKeyword 예: "SSG 랜더스", "LG 트윈스" 등
  /// - page는 1부터
  static Future<List<NewsArticle>> fetchTeamNews({
    required String teamKeyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    // 한국 기사 쪽으로 최대한 유도하려고 "kbo" 같이 섞어줌(원하면 조정)
    final q = '$teamKeyword KBO';

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
}
