/// 扫描到的 Markdown 文件，经过 Front Matter 解析后的数据
class MdFileItem {
  final String filePath;

  /// 不含扩展名的文件名，作为 slug/title 的 fallback
  final String fileName;

  /// slug：优先取 Front Matter 的 slug 字段，否则取 fileName
  final String slug;

  /// title：优先取 Front Matter 的 title 字段，否则取 fileName
  final String title;

  /// 文档正文（已移除 Front Matter）
  final String body;

  /// Front Matter 中是否同时存在 title、slug 字段
  final bool hasLinkFields;

  const MdFileItem({
    required this.filePath,
    required this.fileName,
    required this.slug,
    required this.title,
    required this.body,
    this.hasLinkFields = true,
  });
}
