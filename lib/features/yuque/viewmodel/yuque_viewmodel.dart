import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/yuque_repo.dart';
import '../service/yuque_service.dart';

class YuqueViewModel extends ChangeNotifier {
  static const _keyToken = 'yuque_token';
  static const _keyLogin = 'yuque_login';

  final _service = YuqueService();

  String _token = '';
  String _login = '';
  List<YuqueRepo> _repos = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _configLoaded = false;

  String get token => _token;
  String get login => _login;
  List<YuqueRepo> get repos => List.unmodifiable(_repos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get configLoaded => _configLoaded;

  YuqueViewModel() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken) ?? '';
    _login = prefs.getString(_keyLogin) ?? '';
    _configLoaded = true;
    notifyListeners();
  }

  /// 保存 Token 和用户名至本地存储
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

  /// 保存配置后请求语雀知识库列表
  Future<void> fetchRepos(String token, String login) async {
    await saveConfig(token, login);

    if (_token.isEmpty || _login.isEmpty) {
      _errorMessage = '请填写 Token 和用户名';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _repos = [];
    notifyListeners();

    try {
      _repos = await _service.fetchRepos(_token, _login);
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
