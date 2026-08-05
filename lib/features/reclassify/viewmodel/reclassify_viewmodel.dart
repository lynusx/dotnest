import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/reclassify_result.dart';
import '../service/reclassify_service.dart';

/// 「调整分类」页面的状态与业务逻辑
class ReclassifyViewModel extends ChangeNotifier {
  static const _keyLastSourceDir = 'reclassify_last_source_dir';

  final _service = ReclassifyService();

  String? _sourceDir;
  String? _configPath;
  int? _pendingMdFileCount;
  bool _isProcessing = false;
  ReclassifyOutcome? _outcome;
  String? _errorMessage;

  String? get sourceDir => _sourceDir;
  String? get configPath => _configPath;
  int? get pendingMdFileCount => _pendingMdFileCount;
  bool get isProcessing => _isProcessing;
  ReclassifyOutcome? get outcome => _outcome;
  String? get errorMessage => _errorMessage;
  bool get done => _outcome != null;

  /// 配置文件是否已确定，可以展示"开始分类"入口
  bool get isReadyToRun =>
      _sourceDir != null && _configPath != null && _errorMessage == null;

  /// 选择待处理的目标目录，随后自动执行配置查找规则
  Future<void> pickSourceDir() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDir = prefs.getString(_keyLastSourceDir);
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: '选择待处理的文件夹',
      initialDirectory: lastDir,
    );
    if (path == null) return;

    _sourceDir = path;
    _configPath = null;
    _pendingMdFileCount = null;
    _outcome = null;
    _errorMessage = null;
    notifyListeners();

    await prefs.setString(_keyLastSourceDir, path);
    await _resolveConfig();
  }

  /// 默认配置查找规则：唯一匹配则直接采用，否则自动弹出文件选择器兜底
  Future<void> _resolveConfig() async {
    final dir = _sourceDir;
    if (dir == null) return;

    final candidates = _service.findConfigCandidates(dir);
    if (candidates.length == 1) {
      await _setConfigPath(candidates.first.path);
      return;
    }
    // 未找到或找到多个匹配：自动弹出文件选择器提示用户手动指定
    _configPath = null;
    notifyListeners();
    await pickConfigFileManually();
  }

  /// 手动指定配置文件（自动定位失败时的兜底交互）
  Future<void> pickConfigFileManually() async {
    final dir = _sourceDir;
    if (dir == null) return;
    final result = await FilePicker.pickFiles(
      dialogTitle: '未检测到唯一的 *_api_list.yaml 配置文件，请手动选择',
      type: FileType.custom,
      allowedExtensions: ['yaml'],
      initialDirectory: dir,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    await _setConfigPath(path);
  }

  Future<void> _setConfigPath(String path) async {
    _errorMessage = null;
    try {
      final content = await File(path).readAsString();
      _service.parseConfig(content);
      _configPath = path;
      await _countPendingMdFiles();
    } catch (e) {
      _configPath = null;
      _errorMessage = '配置文件无效或解析失败：${e.toString()}';
    }
    notifyListeners();
  }

  Future<void> _countPendingMdFiles() async {
    final dir = _sourceDir;
    if (dir == null) return;
    final files = await _service.collectMarkdownFiles(dir);
    _pendingMdFileCount = files.length;
  }

  /// 执行批量调整分类
  Future<void> startReclassify() async {
    final dir = _sourceDir;
    final config = _configPath;
    if (dir == null) {
      _errorMessage = '请选择待处理的文件夹';
      notifyListeners();
      return;
    }
    if (config == null) {
      _errorMessage = '请指定分类配置文件';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _outcome = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final outcome = await _service.reclassify(
        sourceDir: dir,
        configPath: config,
      );
      _outcome = outcome;
    } catch (e) {
      _errorMessage = '调整分类失败：${e.toString()}';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 重置状态
  void reset() {
    _outcome = null;
    _errorMessage = null;
    notifyListeners();
  }
}
