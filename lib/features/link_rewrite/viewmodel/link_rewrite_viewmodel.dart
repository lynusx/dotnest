import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../model/link_rewrite_result.dart';
import '../service/link_rewrite_service.dart';

class LinkRewriteViewModel extends ChangeNotifier {
  final _service = LinkRewriteService();

  String? _targetDir;
  String? _urlMapPath;
  Map<String, String>? _urlMap;
  RewriteOutputMode _mode = RewriteOutputMode.overwrite;
  String? _outputDir;
  bool _isProcessing = false;
  List<LinkRewriteFileResult> _results = [];
  LinkRewriteStats? _stats;
  String? _errorMessage;
  bool _done = false;

  String? get targetDir => _targetDir;
  String? get urlMapPath => _urlMapPath;
  Map<String, String>? get urlMap => _urlMap;
  RewriteOutputMode get mode => _mode;
  String? get outputDir => _outputDir;
  bool get isProcessing => _isProcessing;
  List<LinkRewriteFileResult> get results => List.unmodifiable(_results);
  LinkRewriteStats? get stats => _stats;
  String? get errorMessage => _errorMessage;
  bool get done => _done;

  /// 选择待处理的目标目录
  Future<void> pickTargetDir() async {
    final path = await FilePicker.getDirectoryPath(dialogTitle: '选择待处理的文件夹');
    if (path == null) return;
    _targetDir = path;
    _results = [];
    _stats = null;
    _done = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// 选择 url_map.json 并解析为扁平的字符串映射
  Future<void> pickUrlMapFile() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择 url_map.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    try {
      final raw = await File(path).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('根节点必须是对象');
      }
      final map = <String, String>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String || entry.value is! String) {
          throw const FormatException('键值必须均为字符串');
        }
        map[entry.key as String] = entry.value as String;
      }
      _urlMapPath = path;
      _urlMap = map;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'url_map.json 解析失败：${e.toString()}';
    }
    _done = false;
    notifyListeners();
  }

  /// 选择输出目录（仅 mode == newDirectory 时使用）
  Future<void> pickOutputDir() async {
    final path = await FilePicker.getDirectoryPath(dialogTitle: '选择输出目录');
    if (path == null) return;
    _outputDir = path;
    _done = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// 切换输出模式：原地覆盖 / 输出到新目录
  void setMode(RewriteOutputMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// 开始批量重写
  Future<void> startRewrite() async {
    if (_targetDir == null || _targetDir!.isEmpty) {
      _errorMessage = '请选择待处理的文件夹';
      notifyListeners();
      return;
    }
    if (_urlMap == null) {
      _errorMessage = '请选择 url_map.json';
      notifyListeners();
      return;
    }
    if (_mode == RewriteOutputMode.newDirectory &&
        (_outputDir == null || _outputDir!.isEmpty)) {
      _errorMessage = '请选择输出目录';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _results = [];
    _stats = null;
    _done = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _service.processDirectory(
        targetDir: _targetDir!,
        urlMap: _urlMap!,
        mode: _mode,
        outputDir: _outputDir,
      );
      _results = results;
      _stats = _buildStats(results);
      _done = true;
    } catch (e) {
      _errorMessage = '重写失败：${e.toString()}';
    } finally {
      _isProcessing = false;
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

  LinkRewriteStats _buildStats(List<LinkRewriteFileResult> results) {
    final success = results.where((r) => r.success).length;
    final errors = results.where((r) => !r.success).length;
    final totalReplacements = results
        .where((r) => r.success)
        .fold<int>(0, (sum, r) => sum + r.replacementCount);
    return LinkRewriteStats(
      totalFiles: results.length,
      processedFiles: success,
      errorFiles: errors,
      totalReplacements: totalReplacements,
    );
  }
}
