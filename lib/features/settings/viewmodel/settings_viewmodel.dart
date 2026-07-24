import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 承载 App 级显示设置（当前仅字号缩放），持久化至本地存储
class SettingsViewModel extends ChangeNotifier {
  static const _keyFontScale = 'app_font_scale';

  /// 默认字号缩放系数，大于 1.0 以解决默认字体偏小的问题
  static const double defaultFontScale = 1.15;
  static const double minFontScale = 0.85;
  static const double maxFontScale = 1.5;

  double _fontScale = defaultFontScale;

  double get fontScale => _fontScale;

  SettingsViewModel() {
    _loadFontScale();
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_keyFontScale);
    if (saved != null) {
      _fontScale = saved.clamp(minFontScale, maxFontScale);
      notifyListeners();
    }
  }

  /// 更新字号缩放并持久化，超出范围的值会被裁剪
  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(minFontScale, maxFontScale);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, _fontScale);
  }

  Future<void> resetFontScale() => setFontScale(defaultFontScale);
}
