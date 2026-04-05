class NaverNewsArticle {
  final String title;
  final String description;
  final String originallink;
  final String link;
  final DateTime? pubDate;
  final String? imageUrl;

  NaverNewsArticle({
    required this.title,
    required this.description,
    required this.originallink,
    required this.link,
    required this.pubDate,
    this.imageUrl,
  });

  static String _stripHtml(String s) {
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
      parsed = DateTime.tryParse(pub);
    } catch (_) {}

    return NaverNewsArticle(
      title: _stripHtml((json['title'] ?? '').toString()),
      description: _stripHtml((json['description'] ?? '').toString()),
      originallink: (json['originallink'] ?? '').toString(),
      link: (json['link'] ?? '').toString(),
      pubDate: parsed,
      imageUrl: null,
    );
  }

  NaverNewsArticle copyWith({
    String? title,
    String? description,
    String? originallink,
    String? link,
    DateTime? pubDate,
    String? imageUrl,
  }) {
    return NaverNewsArticle(
      title: title ?? this.title,
      description: description ?? this.description,
      originallink: originallink ?? this.originallink,
      link: link ?? this.link,
      pubDate: pubDate ?? this.pubDate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}


