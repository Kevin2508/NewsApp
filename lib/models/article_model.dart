class Article {
  final int id;
  final String title;
  final String url;
  final String description;
  final String content;
  final String category;
  final double similarityScore;
  final String imageUrl;
  final DateTime? publishedAt;
  final String author;

  Article({
    required this.id,
    required this.title,
    required this.url,
    this.description = '',
    this.content = '',
    this.category = '',
    this.similarityScore = 0.0,
    this.imageUrl = '',
    this.publishedAt,
    this.author = '',
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      url: json['url'] ?? '#',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      similarityScore: json['similarity_score']?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      author: json['author'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'content': content,
      'category': category,
      'similarity_score': similarityScore,
      'image_url': imageUrl,
      'published_at': publishedAt?.toIso8601String(),
      'author': author,
    };
  }

  @override
  String toString() {
    return 'Article(id: $id, title: $title, url: $url, similarityScore: $similarityScore)';
  }
}
