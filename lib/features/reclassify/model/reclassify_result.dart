/// 单条警告的类型
enum ReclassifyWarningType {
  missingTitle,
  unmatchedTitle,
}

/// 分类过程中产生的单条警告
class ReclassifyWarning {
  final String relativePath;
  final ReclassifyWarningType type;

  const ReclassifyWarning({
    required this.relativePath,
    required this.type,
  });

  String get message {
    switch (type) {
      case ReclassifyWarningType.missingTitle:
        return '缺少 title 字段，已跳过（保留在根目录）';
      case ReclassifyWarningType.unmatchedTitle:
        return 'title 未匹配到任何分类，已跳过（保留在根目录）';
    }
  }
}

/// 批量调整分类的统计信息
class ReclassifyStats {
  final int totalFiles;
  final int movedFiles;
  final int missingTitleFiles;
  final int unmatchedFiles;

  const ReclassifyStats({
    required this.totalFiles,
    required this.movedFiles,
    required this.missingTitleFiles,
    required this.unmatchedFiles,
  });
}

/// 单次调整分类的完整结果
class ReclassifyOutcome {
  final ReclassifyStats stats;
  final List<ReclassifyWarning> warnings;

  const ReclassifyOutcome({
    required this.stats,
    required this.warnings,
  });
}
