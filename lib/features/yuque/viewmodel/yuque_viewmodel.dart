import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
