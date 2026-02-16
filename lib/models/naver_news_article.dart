class NaverNewsArticle {
  final String title;
  final String description;
  final String originallink;
  final String link;
  final DateTime? pubDate;

  NaverNewsArticle({
    required this.title,
    required this.description,
    required this.originallink,
    required this.link,
    required this.pubDate,
  });

  static String _stripHtml(String s) {
    // 네이버 뉴스는 <b>키워드</b> 같은 태그가 섞여서 옴
    final noTags = s.replaceAll(RegExp(r'<[^>]*>'), '');
    return noTags
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  factory NaverNewsArticle.fromJson(Map<String, dynamic> json) {
    final pub = (json['pubDate'] as String?) ?? '';
    DateTime? parsed;
    try {
      // 예: "Mon, 17 Feb 2026 12:34:56 +0900"
      parsed = DateTime.tryParse(pub); // 실패 가능
    } catch (_) {}

    return NaverNewsArticle(
      title: _stripHtml((json['title'] ?? '').toString()),
      description: _stripHtml((json['description'] ?? '').toString()),
      originallink: (json['originallink'] ?? '').toString(),
      link: (json['link'] ?? '').toString(),
      pubDate: parsed,
    );
  }
}


