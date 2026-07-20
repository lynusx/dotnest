import 'package:flutter/foundation.dart';

enum NavPage { extract, yuque }

const double kSidebarMinWidth = 140;
const double kSidebarMaxWidth = 320;
const double kSidebarDefaultWidth = 200;

extension NavPageExtension on NavPage {
  String get label {
    switch (this) {
      case NavPage.extract:
        return 'API 提取';
      case NavPage.yuque:
        return '语雀同步';
    }
  }

  String get iconAsset {
    switch (this) {
      case NavPage.extract:
        return 'code';
      case NavPage.yuque:
        return 'sync';
    }
  }
}

class NavigationViewModel extends ChangeNotifier {
  NavPage _currentPage = NavPage.extract;
  double _sidebarWidth = kSidebarDefaultWidth;

  NavPage get currentPage => _currentPage;
  double get sidebarWidth => _sidebarWidth;

  void navigateTo(NavPage page) {
    if (_currentPage == page) return;
    _currentPage = page;
    notifyListeners();
  }

  void setSidebarWidth(double width) {
    final clamped = width.clamp(kSidebarMinWidth, kSidebarMaxWidth);
    if (_sidebarWidth == clamped) return;
    _sidebarWidth = clamped;
    notifyListeners();
  }
}
