import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/md_file_item.dart';
import '../model/scan_group_node.dart';
import '../model/upload_result.dart';
import '../model/yuque_doc.dart';
import '../model/yuque_repo.dart';
import '../service/yuque_service.dart';

class YuqueViewModel extends ChangeNotifier {
  static const _keyToken = 'yuque_token';
  static const _keyLogin = 'yuque_login';
  static const _keyRepos = 'yuque_repos_cache';
  static const _keyDocBookId = 'yuque_doc_book_id';
  static const _keyDocs = 'yuque_docs_cache';

  final _service = YuqueService();

  String _token = '';
  String _login = '';
  List<YuqueRepo> _repos = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _configLoaded = false;

  // ── 文档列表状态 ─────────────────────────────────────────────────────────────
  String _docBookId = '';
  List<YuqueDoc> _docs = [];
  bool _isDocsLoading = false;
  String? _docsErrorMessage;

  String get token => _token;
  String get login => _login;
  List<YuqueRepo> get repos => List.unmodifiable(_repos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get configLoaded => _configLoaded;

  String get docBookId => _docBookId;
  List<YuqueDoc> get docs => List.unmodifiable(_docs);
  bool get isDocsLoading => _isDocsLoading;
  String? get docsErrorMessage => _docsErrorMessage;

  // ── 批量创建状态 ─────────────────────────────────────────────────────────────
  String _batchBookId = '';
  String? _batchFolderPath;
  List<MdFileItem> _scannedFiles = [];
  List<UploadResult> _uploadResults = [];
  bool _isBatchUploading = false;
  int _batchUploadedCount = 0;
  String? _batchErrorMessage;
  String _exportBaseUrl = '';

  /// 已折叠的分组路径集合（分组树节点的 [ScanGroupNode.path]）
  final Set<String> _collapsedGroupPaths = {};

  String get batchBookId => _batchBookId;
  String get exportBaseUrl => _exportBaseUrl;
  String? get batchFolderPath => _batchFolderPath;
  List<MdFileItem> get scannedFiles => List.unmodifiable(_scannedFiles);
  List<UploadResult> get uploadResults => List.unmodifiable(_uploadResults);
  bool get isBatchUploading => _isBatchUploading;
  int get batchUploadedCount => _batchUploadedCount;
  String? get batchErrorMessage => _batchErrorMessage;

  /// 按源目录结构分组后的扫描结果（跳过根目录）
  ({List<MdFileItem> rootFiles, List<ScanGroupNode> groups})
  get scanGroupTree =>
      ScanGroupNode.buildTree(_scannedFiles, _batchFolderPath ?? '');

  bool isGroupCollapsed(String groupPath) =>
      _collapsedGroupPaths.contains(groupPath);

  void toggleGroupCollapsed(String groupPath) {
    if (!_collapsedGroupPaths.remove(groupPath)) {
      _collapsedGroupPaths.add(groupPath);
    }
    notifyListeners();
  }

  YuqueViewModel() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken) ?? '';
    _login = prefs.getString(_keyLogin) ?? '';
    // 恢复上次缓存的知识库列表
    final cached = prefs.getString(_keyRepos);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        _repos = list
            .map((e) => YuqueRepo.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    // 恢复上次缓存的文档列表
    _docBookId = prefs.getString(_keyDocBookId) ?? '';
    final cachedDocs = prefs.getString(_keyDocs);
    if (cachedDocs != null && cachedDocs.isNotEmpty) {
      try {
        final list = jsonDecode(cachedDocs) as List<dynamic>;
        _docs = list
            .map((e) => YuqueDoc.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    _configLoaded = true;
    notifyListeners();
  }

  /// 仅保存 Token 和用户名至本地存储
  Future<void> saveConfig(String token, String login) async {
    _token = token.trim();
    _login = login.trim();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyToken, _token),
      prefs.setString(_keyLogin, _login),
    ]);
    notifyListeners();
  }

  /// 保存配置后请求语雀知识库列表，结果持久化缓存
  Future<void> fetchRepos(String token, String login) async {
    await saveConfig(token, login);
    if (_token.isEmpty || _login.isEmpty) {
      _errorMessage = '请填写 Token 和用户名';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _repos = await _service.fetchRepos(_token, _login);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyRepos,
        jsonEncode(_repos.map((r) => r.toJson()).toList()),
      );
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 请求指定知识库的全部文档，结果持久化缓存
  Future<void> fetchDocs(String bookId) async {
    _docBookId = bookId.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDocBookId, _docBookId);
    if (_token.isEmpty) {
      _docsErrorMessage = '请先填写并保存 API Token';
      notifyListeners();
      return;
    }
    if (_docBookId.isEmpty) {
      _docsErrorMessage = '请填写知识库 ID';
      notifyListeners();
      return;
    }
    final id = int.tryParse(_docBookId);
    if (id == null) {
      _docsErrorMessage = '知识库 ID 必须为数字';
      notifyListeners();
      return;
    }
    _isDocsLoading = true;
    _docsErrorMessage = null;
    notifyListeners();
    try {
      final (fetchedDocs, _) = await _service.fetchAllDocs(_token, id);
      _docs = fetchedDocs;
      await prefs.setString(
        _keyDocs,
        jsonEncode(_docs.map((d) => d.toJson()).toList()),
      );
    } on Exception catch (e) {
      _docsErrorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isDocsLoading = false;
      notifyListeners();
    }
  }

  // ── 批量创建方法 ─────────────────────────────────────────────────────────────

  /// 选择本地文件夹，选中后自动扫描 .md 文件
  Future<void> pickBatchFolder() async {
    final result = await FilePicker.getDirectoryPath();
    if (result == null) return;
    _batchFolderPath = result;
    _scannedFiles = [];
    _uploadResults = [];
    _batchUploadedCount = 0;
    _batchErrorMessage = null;
    _collapsedGroupPaths.clear();
    notifyListeners();
    await _scanFolder();
  }

  /// 将扫描结果导出为结构化目录 .md 文件：按源目录分组（跳过根目录），
  /// 每组下按 `- [title](slug)` 列出文件；导出成功返回保存路径，用户取消返回 null
  Future<String?> exportGroupedMarkdown() async {
    final tree = scanGroupTree;
    final buffer = StringBuffer();

    void writeGroup(ScanGroupNode node, int depth) {
      final indent = '  ' * depth;
      buffer.writeln('$indent- [${node.name}]()');
      for (final file in node.files) {
        buffer.writeln('$indent  - [${file.title}](${file.slug})');
      }
      for (final child in node.children) {
        writeGroup(child, depth + 1);
      }
    }

    for (final file in tree.rootFiles) {
      buffer.writeln('- [${file.title}](${file.slug})');
    }
    for (final group in tree.groups) {
      writeGroup(group, 0);
    }

    final savedPath = await FilePicker.saveFile(
      dialogTitle: '导出目录',
      fileName: 'toc.md',
      type: FileType.custom,
      allowedExtensions: ['md'],
      bytes: utf8.encode(buffer.toString()),
    );
    return savedPath;
  }

  /// 将扫描结果导出为 `{title: baseUrl/slug}` 结构的 .json 文件；
  /// 导出成功返回保存路径，用户取消返回 null
  Future<String?> exportLinksJson(String baseUrl) async {
    _exportBaseUrl = baseUrl.trim();
    final normalizedBase = _exportBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final links = <String, String>{
      for (final file in _scannedFiles)
        file.title: '$normalizedBase/${file.slug}',
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(links);

    final savedPath = await FilePicker.saveFile(
      dialogTitle: '导出链接',
      fileName: 'links.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: utf8.encode(jsonStr),
    );
    return savedPath;
  }

  /// 递归扫描文件夹中的 .md 文件并解析 Front Matter
  Future<void> _scanFolder() async {
    if (_batchFolderPath == null) return;
    final dir = Directory(_batchFolderPath!);
    final items = <MdFileItem>[];
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.toLowerCase().endsWith('.md')) {
          final content = await entity.readAsString();
          final name = entity.uri.pathSegments.last.replaceAll(
            RegExp(r'\.[mM][dD]$'),
            '',
          );
          final (:slug, :title, :body) = _parseFrontMatter(content);
          items.add(
            MdFileItem(
              filePath: entity.path,
              fileName: name,
              slug: slug ?? name,
              title: title ?? name,
              body: body,
            ),
          );
        }
      }
    } on FileSystemException catch (e) {
      _batchErrorMessage = '读取文件夹失败：${e.message}';
      notifyListeners();
      return;
    }
    items.sort((a, b) => a.filePath.compareTo(b.filePath));
    _scannedFiles = items;
    notifyListeners();
  }

  /// 批量创建：逐个上传扫描到的文档，实时更新进度
  Future<void> startBatchUpload(String bookId) async {
    _batchBookId = bookId.trim();
    if (_token.isEmpty) {
      _batchErrorMessage = '请先填写并保存 API Token';
      notifyListeners();
      return;
    }
    if (_batchBookId.isEmpty) {
      _batchErrorMessage = '请填写知识库 ID';
      notifyListeners();
      return;
    }
    final bid = int.tryParse(_batchBookId);
    if (bid == null) {
      _batchErrorMessage = '知识库 ID 必须为数字';
      notifyListeners();
      return;
    }
    if (_scannedFiles.isEmpty) {
      _batchErrorMessage = '请先选择包含 .md 文件的文件夹';
      notifyListeners();
      return;
    }
    _isBatchUploading = true;
    _uploadResults = [];
    _batchUploadedCount = 0;
    _batchErrorMessage = null;
    notifyListeners();

    for (final file in _scannedFiles) {
      try {
        final docId = await _service.createDoc(
          _token,
          bid,
          file.slug,
          file.title,
          file.body,
        );
        _uploadResults = [
          ..._uploadResults,
          UploadResult(file: file, success: true, docId: docId),
        ];
      } on Exception catch (e) {
        _uploadResults = [
          ..._uploadResults,
          UploadResult(
            file: file,
            success: false,
            error: e.toString().replaceFirst('Exception: ', ''),
          ),
        ];
      }
      _batchUploadedCount++;
      notifyListeners();
    }

    _isBatchUploading = false;
    notifyListeners();
  }

  // ── 目录更新状态 ─────────────────────────────────────────────────────────────
  String _tocBookId = '';
  String? _tocFileName;
  String? _tocRawContent;
  bool _isTocUpdating = false;
  String? _tocErrorMessage;
  bool _tocUpdated = false;

  String get tocBookId => _tocBookId;
  String? get tocFileName => _tocFileName;
  String? get tocRawContent => _tocRawContent;
  bool get isTocUpdating => _isTocUpdating;
  String? get tocErrorMessage => _tocErrorMessage;
  bool get tocUpdated => _tocUpdated;

  /// 选择单个 .md 文件，读取原始内容作为 toc
  Future<void> pickTocFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final pf = result.files.first;
    final path = pf.path;
    if (path == null) return;
    _tocFileName = pf.name;
    _tocRawContent = await File(path).readAsString();
    _tocUpdated = false;
    _tocErrorMessage = null;
    notifyListeners();
  }

  /// 清除已选文件
  void clearTocFile() {
    _tocFileName = null;
    _tocRawContent = null;
    _tocUpdated = false;
    _tocErrorMessage = null;
    notifyListeners();
  }

  /// 调用 PUT /api/v2/repos/{book_id} 更新知识库目录
  Future<void> updateToc(String bookId) async {
    _tocBookId = bookId.trim();
    if (_token.isEmpty) {
      _tocErrorMessage = '请先填写并保存 API Token';
      notifyListeners();
      return;
    }
    if (_tocBookId.isEmpty) {
      _tocErrorMessage = '请填写知识库 ID';
      notifyListeners();
      return;
    }
    final bid = int.tryParse(_tocBookId);
    if (bid == null) {
      _tocErrorMessage = '知识库 ID 必须为数字';
      notifyListeners();
      return;
    }
    if (_tocRawContent == null) {
      _tocErrorMessage = '请先选择 .md 文件';
      notifyListeners();
      return;
    }
    _isTocUpdating = true;
    _tocErrorMessage = null;
    _tocUpdated = false;
    notifyListeners();
    try {
      await _service.updateToc(_token, bid, _tocRawContent!);
      _tocUpdated = true;
    } on Exception catch (e) {
      _tocErrorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isTocUpdating = false;
      notifyListeners();
    }
  }
}

// ── Front Matter 解析（仅提取 slug / title，其余保留为 body）────────────────────

({String? slug, String? title, String body}) _parseFrontMatter(String content) {
  if (!content.startsWith('---')) {
    return (slug: null, title: null, body: content);
  }
  final fmEnd = content.indexOf('\n---', 3);
  if (fmEnd == -1) {
    return (slug: null, title: null, body: content);
  }
  final fmBlock = content.substring(3, fmEnd);
  String body = content.substring(fmEnd + 4);
  if (body.startsWith('\n')) body = body.substring(1);

  String? slug;
  String? title;
  for (final rawLine in fmBlock.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final colonIdx = line.indexOf(':');
    if (colonIdx == -1) continue;
    final key = line.substring(0, colonIdx).trim();
    final value = _stripFmValue(line.substring(colonIdx + 1).trim());
    if (key == 'slug' && value.isNotEmpty) slug = value;
    if (key == 'title' && value.isNotEmpty) title = value;
  }
  return (slug: slug, title: title, body: body);
}

String _stripFmValue(String s) {
  if (s.length >= 2 &&
      ((s.startsWith('"') && s.endsWith('"')) ||
          (s.startsWith("'") && s.endsWith("'")))) {
    return s.substring(1, s.length - 1);
  }
  return s;
}
