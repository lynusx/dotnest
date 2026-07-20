/// 对应语雀 OpenAPI V2Doc 数据模型
class YuqueDoc {
  final int id;
  final String slug;
  final String title;
  final int bookId;
  final int userId;

  const YuqueDoc({
    required this.id,
    required this.slug,
    required this.title,
    required this.bookId,
    required this.userId,
  });

  factory YuqueDoc.fromJson(Map<String, dynamic> json) {
    return YuqueDoc(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      bookId: (json['book_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'book_id': bookId,
        'user_id': userId,
      };
}
