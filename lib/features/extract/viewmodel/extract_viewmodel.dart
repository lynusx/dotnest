import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../model/extract_result.dart';
import '../service/dart_analyzer_service.dart';

class ExtractViewModel extends ChangeNotifier {
  final _service = DartAnalyzerService();

  String? _sourceDir;
  String? _outputDir;
  bool _isExtracting = false;
  List<ExtractResult> _results = [];
  ExtractStats? _stats;
  String? _errorMessage;
  bool _done = false;

  String? get sourceDir => _sourceDir;
  String? get outputDir => _outputDir;
  bool get isExtracting => _isExtracting;
  List<ExtractResult> get results => List.unmodifiable(_results);
  ExtractStats? get stats => _stats;
  String? get errorMessage => _errorMessage;
  bool get done => _done;

  /// 选择源码目录
  Future<void> pickSourceDir() async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: '选择 Dart 源码目录',
    );
    if (path == null) return;
    _sourceDir = path;
    _results = [];
    _stats = null;
    _done = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// 选择输出目录
  Future<void> pickOutputDir() async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: '选择 Markdown 输出目录',
    );
    if (path == null) return;
    _outputDir = path;
    _done = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// 开始提取
  Future<void> startExtract() async {
    if (_sourceDir == null || _sourceDir!.isEmpty) {
      _errorMessage = '请选择 Dart 源码目录';
      notifyListeners();
      return;
    }
    if (_outputDir == null || _outputDir!.isEmpty) {
      _errorMessage = '请选择输出目录';
      notifyListeners();
      return;
    }

    _isExtracting = true;
    _results = [];
    _stats = null;
    _done = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _service.extractFromDirectory(
        _sourceDir!,
        _outputDir!,
      );
      _results = results;
      _stats = _buildStats(results);
      _done = true;
    } catch (e) {
      _errorMessage = '提取失败：${e.toString()}';
    } finally {
      _isExtracting = false;
      notifyListeners();
    }
  }

  /// 重置状态
  void reset() {
    _results = [];
    _stats = null;
    _done = false;
    _errorMessage = null;
    notifyListeners();
  }

  ExtractStats _buildStats(List<ExtractResult> results) {
    final success = results.where((r) => r.success).length;
    final errors = results.where((r) => !r.success).length;
    return ExtractStats(
      totalFiles: results.length,
      processedFiles: success,
      skippedFiles: 0,
      generatedDocs: success,
      errors: errors,
    );
  }
}
