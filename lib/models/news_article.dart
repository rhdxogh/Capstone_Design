class NewsArticle {
  final String title;
  final String url;
  final String? imageUrl;
  final String? source;
  final DateTime? publishedAt;
  final String? description;

  NewsArticle({
    required this.title,
    required this.url,
    this.imageUrl,
    this.source,
    this.publishedAt,
    this.description,
  });

  factory NewsArticle.fromNewsApi(Map<String, dynamic> json) {
    return NewsArticle(
      title: (json['title'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      imageUrl: json['urlToImage']?.toString(),
      source: (json['source'] is Map) ? (json['source']['name']?.toString()) : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      description: json['description']?.toString(),
    );
  }
}
