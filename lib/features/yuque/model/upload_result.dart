import 'md_file_item.dart';

/// 单个文件的上传结果
class UploadResult {
  final MdFileItem file;
  final bool success;

  /// 上传失败时的错误信息
  final String? error;

  /// 上传成功时语雀返回的文档 ID
  final int? docId;

  const UploadResult({
    required this.file,
    required this.success,
    this.error,
    this.docId,
  });
}
