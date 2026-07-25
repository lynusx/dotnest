/// 单个文件的重写结果
class LinkRewriteFileResult {
  final String relativePath;
  final int replacementCount;
  final bool success;
  final String? error;

  const LinkRewriteFileResult({
    required this.relativePath,
    required this.replacementCount,
    required this.success,
    this.error,
  });
}

/// 批量重写统计信息
class LinkRewriteStats {
  final int totalFiles;
  final int processedFiles;
  final int errorFiles;
  final int totalReplacements;

  const LinkRewriteStats({
    required this.totalFiles,
    required this.processedFiles,
    required this.errorFiles,
    required this.totalReplacements,
  });
}

/// 输出模式：原地覆盖 / 写入新目录
enum RewriteOutputMode { overwrite, newDirectory }
