/// 对应语雀 OpenAPI V2Book 数据模型
class YuqueRepo {
  final int id;
  final String slug;
  final String name;
  final int userId;
  final String description;
  final int itemsCount;

  const YuqueRepo({
    required this.id,
    required this.slug,
    required this.name,
    required this.userId,
    required this.description,
    required this.itemsCount,
  });

  factory YuqueRepo.fromJson(Map<String, dynamic> json) {
    return YuqueRepo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
    );
  }
}
