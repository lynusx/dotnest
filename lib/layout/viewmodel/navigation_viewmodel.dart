import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum NavPage {
  extract,
  yuqueRepos,
  yuqueDocs,
  yuqueBatchUpload,
  yuqueTocUpdate,
  linkRewrite,
  reclassify,
  settings,
}

const List<NavPage> kNavPageOrder = [
  NavPage.extract,
  NavPage.yuqueRepos,
  NavPage.yuqueDocs,
  NavPage.yuqueBatchUpload,
  NavPage.yuqueTocUpdate,
  NavPage.linkRewrite,
  NavPage.reclassify,
];

extension NavPageExtension on NavPage {
  String get label {
    switch (this) {
      case NavPage.extract:
        return 'API 提取';
      case NavPage.yuqueRepos:
        return '知识库';
      case NavPage.yuqueDocs:
        return '文档列表';
      case NavPage.yuqueBatchUpload:
        return '批量创建';
      case NavPage.yuqueTocUpdate:
        return '目录更新';
      case NavPage.linkRewrite:
        return '链接重写';
      case NavPage.reclassify:
        return '调整分类';
      case NavPage.settings:
        return '设置';
    }
  }

  IconData get icon {
    switch (this) {
      case NavPage.extract:
        return Icons.data_object_rounded;
      case NavPage.yuqueRepos:
        return Icons.folder_outlined;
      case NavPage.yuqueDocs:
        return Icons.description_outlined;
      case NavPage.yuqueBatchUpload:
        return Icons.upload_file_outlined;
      case NavPage.yuqueTocUpdate:
        return Icons.account_tree_outlined;
      case NavPage.linkRewrite:
        return Icons.link_rounded;
      case NavPage.reclassify:
        return Icons.category_outlined;
      case NavPage.settings:
        return Icons.settings_outlined;
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
      case NavPage.linkRewrite:
      case NavPage.reclassify:
      case NavPage.settings:
        return false;
    }
  }
}

class NavigationViewModel extends ChangeNotifier {
  NavPage _currentPage = NavPage.extract;
  // tracks the last non-settings page so NavigationRail always has a valid index
  NavPage _lastContentPage = NavPage.extract;
  String _appVersion = '';

  NavigationViewModel() {
    _loadAppVersion();
  }

  NavPage get currentPage => _currentPage;

  /// 应用版本号（如 "v0.6.0"），加载完成前为空字符串
  String get appVersion => _appVersion;

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    _appVersion = 'v${info.version}';
    notifyListeners();
  }

  /// Index for NavigationRail — always valid, holds the last content page
  /// even when the user is on the Settings screen.
  int get selectedIndex => kNavPageOrder.indexOf(_lastContentPage);

  void navigateTo(NavPage page) {
    if (_currentPage == page) return;
    if (page != NavPage.settings) {
      _lastContentPage = page;
    }
    _currentPage = page;
    notifyListeners();
  }

  void navigateToIndex(int index) {
    if (index < 0 || index >= kNavPageOrder.length) return;
    navigateTo(kNavPageOrder[index]);
  }
}
