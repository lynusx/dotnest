import 'md_file_item.dart';

/// 扫描结果按目录结构分组后的树节点
class ScanGroupNode {
  /// 目录名（相对于父级的单段名称）
  final String name;

  /// 相对于所选根文件夹的完整路径，用作展开/折叠状态的唯一 key
  final String path;

  /// 直接位于该目录下的文件
  final List<MdFileItem> files;

  /// 子目录分组
  final List<ScanGroupNode> children;

  const ScanGroupNode({
    required this.name,
    required this.path,
    required this.files,
    required this.children,
  });

  /// 该分组及其所有子分组下的文件总数
  int get totalFileCount =>
      files.length + children.fold(0, (sum, c) => sum + c.totalFileCount);

  /// 依据文件相对根目录的路径构建分组树（跳过根目录本身）。
  /// 直接位于根目录下的文件会作为 [rootFiles] 单独返回，不计入任何分组。
  static ({List<MdFileItem> rootFiles, List<ScanGroupNode> groups}) buildTree(
    List<MdFileItem> files,
    String rootPath,
  ) {
    final normalizedRoot = rootPath.replaceAll('\\', '/');
    final root = _MutableNode('', '');
    for (final file in files) {
      final normalizedPath = file.filePath.replaceAll('\\', '/');
      var relative = normalizedPath;
      if (normalizedRoot.isNotEmpty &&
          normalizedPath.startsWith(normalizedRoot)) {
        relative = normalizedPath.substring(normalizedRoot.length);
      }
      final segments = relative
          .split('/')
          .where((s) => s.isNotEmpty)
          .toList();
      if (segments.isNotEmpty) segments.removeLast(); // 去掉文件名，只保留目录层级

      var current = root;
      var pathBuilder = '';
      for (final segment in segments) {
        pathBuilder = pathBuilder.isEmpty ? segment : '$pathBuilder/$segment';
        current = current.children.putIfAbsent(
          segment,
          () => _MutableNode(segment, pathBuilder),
        );
      }
      current.files.add(file);
    }
    return (rootFiles: root.files, groups: root.toChildNodes());
  }
}

class _MutableNode {
  final String name;
  final String path;
  final List<MdFileItem> files = [];
  final Map<String, _MutableNode> children = {};

  _MutableNode(this.name, this.path);

  List<ScanGroupNode> toChildNodes() {
    final nodes = children.values.map((n) => n._toNode()).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return nodes;
  }

  ScanGroupNode _toNode() => ScanGroupNode(
    name: name,
    path: path,
    files: files,
    children: toChildNodes(),
  );
}
