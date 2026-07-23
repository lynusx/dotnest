/// API 提取结果数据模型
class ExtractResult {
  final String apiName;
  final String fileName;
  final ApiType apiType;
  final String sourcePath;
  final bool success;
  final String? error;

  const ExtractResult({
    required this.apiName,
    required this.fileName,
    required this.apiType,
    required this.sourcePath,
    required this.success,
    this.error,
  });
}

/// API 类型枚举
enum ApiType {
  classType('class'),
  mixin('mixin'),
  enumType('enum'),
  extension('extension'),
  typedef('typedef'),
  function('function'),
  variable('variable'),
  library('library');

  final String keyword;
  const ApiType(this.keyword);
}

/// 提取统计信息
class ExtractStats {
  final int totalFiles;
  final int processedFiles;
  final int skippedFiles;
  final int generatedDocs;
  final int errors;

  const ExtractStats({
    required this.totalFiles,
    required this.processedFiles,
    required this.skippedFiles,
    required this.generatedDocs,
    required this.errors,
  });

  ExtractStats copyWith({
    int? totalFiles,
    int? processedFiles,
    int? skippedFiles,
    int? generatedDocs,
    int? errors,
  }) {
    return ExtractStats(
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      generatedDocs: generatedDocs ?? this.generatedDocs,
      errors: errors ?? this.errors,
    );
  }
}
