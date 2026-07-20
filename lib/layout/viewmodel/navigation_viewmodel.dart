import 'package:flutter/foundation.dart';

enum NavPage { extract, yuqueRepos, yuqueDocs, yuqueBatchUpload, yuqueTocUpdate }

const double kSidebarMinWidth = 140;
const double kSidebarMaxWidth = 320;
const double kSidebarDefaultWidth = 200;

extension NavPageExtension on NavPage {
  String get label {
    switch (this) {
      case NavPage.extract:
        return 'API 提取';
      case NavPage.yuqueRepos:
        return '知识库列表';
      case NavPage.yuqueDocs:
        return '文档列表';
      case NavPage.yuqueBatchUpload:
        return '批量创建';
      case NavPage.yuqueTocUpdate:
        return '目录更新';
    }
  }

  bool get isYuquePage {
    switch (this) {
      case NavPage.yuqueRepos:
      case NavPage.yuqueDocs:
      case NavPage.yuqueBatchUpload:
      case NavPage.yuqueTocUpdate:
        return true;
      case NavPage.extract:
        return false;
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
