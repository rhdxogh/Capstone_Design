import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/naver_api.dart';
import '../models/naver_news_article.dart';

class NaverNewsService {
  static const _base = 'https://openapi.naver.com/v1/search/news.json';

  /// 팀별 "최대한 많이" 가져오기 위한 키워드 묶음
  /// - strong: 팀 고유 식별 단어(정확도/양 둘 다 확보)
  /// - weak: 지역/홈구장/별칭 등(양 증가용)
  static ({List<String> strong, List<String> weak}) _teamKeys(String teamNameOrId) {
    final t = teamNameOrId.toLowerCase();

    if (t.contains('ssg') || t.contains('랜더스') || t.contains('landers')) {
      return (strong: ['SSG 랜더스', '랜더스'], weak: ['SSG', '인천', '문학', '랜더스필드']);
    }
    if (t.contains('키움') || t.contains('히어로즈') || t.contains('kiwoom')) {
      return (strong: ['키움 히어로즈', '키움', '히어로즈'], weak: ['고척']);
    }
    if (t == 'kt' || t.contains('위즈') || t.contains('wiz')) {
      return (strong: ['KT 위즈', '위즈'], weak: ['KT', '수원']);
    }
    if (t.contains('lg') || t.contains('트윈스') || t.contains('twins')) {
      return (strong: ['LG 트윈스', '트윈스'], weak: ['LG', '잠실']);
    }
    if (t.contains('두산') || t.contains('베어스') || t.contains('doosan')) {
      return (strong: ['두산 베어스', '두산', '베어스'], weak: ['잠실']);
    }
    if (t.contains('기아') || t.contains('kia') || t.contains('타이거즈')) {
      return (strong: ['KIA 타이거즈', '기아 타이거즈', '타이거즈'], weak: ['광주', '챔피언스필드']);
    }
    if (t.contains('삼성') || t.contains('라이온즈') || t.contains('samsung')) {
      return (strong: ['삼성 라이온즈', '삼성', '라이온즈'], weak: ['대구']);
    }
    if (t.contains('nc') || t.contains('다이노스') || t.contains('dinos')) {
      return (strong: ['NC 다이노스', '다이노스'], weak: ['NC', '창원']);
    }
    if (t.contains('롯데') || t.contains('자이언츠') || t.contains('lotte')) {
      return (strong: ['롯데 자이언츠', '롯데', '자이언츠'], weak: ['부산', '사직']);
    }
    if (t.contains('한화') || t.contains('이글스') || t.contains('hanwha')) {
      return (strong: ['한화 이글스', '한화', '이글스'], weak: ['대전']);
    }

    return (strong: [teamNameOrId], weak: const []);
  }

  /// ✅ "많이 가져오면서도 야구 관련성"을 유지하는 쿼리 생성
  /// - 네이버 검색은 따옴표/OR/AND가 완전한 Boolean은 아니지만, 키워드 구성만 잘해도 효과 큼
  static String _buildQuery(String teamNameOrId) {
    final keys = _teamKeys(teamNameOrId);
    final strong = keys.strong;
    final weak = keys.weak;

    // 양을 늘리기 위해 strong + weak를 적절히 섞고,
    // 야구 필수 단어를 붙인다.
    final parts = <String>[
      ...strong,
      ...weak,
      'KBO',
      '프로야구',
      '야구',
    ];

    // 중복 제거
    final uniq = <String>{};
    final finalParts = <String>[];
    for (final p in parts) {
      final k = p.trim();
      if (k.isEmpty) continue;
      if (uniq.add(k)) finalParts.add(k);
    }

    // 네이버는 query 문자열 그대로 검색하므로 너무 길면 오히려 품질 떨어질 수 있음.
    // strong 우선 + weak 일부만(최대 6개 정도)로 제한.
    final limited = <String>[
      ...strong,
      ...weak.take(6),
      'KBO',
      '프로야구',
    ];

    return limited.join(' ');
  }

  /// 네이버 뉴스 검색
  /// - display: 10~100 (최대 100)
  /// - start: 1~1000
  /// - sort: date(최신) / sim(정확도)
  static Future<List<NaverNewsArticle>> fetchTeamNews({
    required String teamNameOrId,
    int start = 1,
    int display = 30,
    String sort = 'date',
  }) async {
    if (display < 1) display = 1;
    if (display > 100) display = 100;
    if (start < 1) start = 1;
    if (start > 1000) start = 1000;

    final query = _buildQuery(teamNameOrId);

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
    final items = (data['items'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();

    final articles = items.map(NaverNewsArticle.fromJson).toList();

    // ✅ 중복 제거(같은 링크가 반복될 때가 있음)
    final seen = <String>{};
    final deduped = <NaverNewsArticle>[];
    for (final a in articles) {
      final key = (a.originallink.isNotEmpty ? a.originallink : a.link).trim();
      if (key.isEmpty) continue;
      if (seen.add(key)) deduped.add(a);
    }

    return deduped;
  }
}



