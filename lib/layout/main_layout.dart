import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../features/extract/view/extract_page.dart';
import '../features/yuque/view/repo_list_page.dart';
import '../features/yuque/view/doc_list_page.dart';
import '../features/yuque/view/batch_upload_page.dart';
import '../features/yuque/view/toc_update_page.dart';
import 'viewmodel/navigation_viewmodel.dart';
import '../features/settings/view/settings_page.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NavigationViewModel>();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.sidebarBg,
            selectedIndex: vm.selectedIndex,
            onDestinationSelected: vm.navigateToIndex,
            labelType: NavigationRailLabelType.all,
            indicatorColor: AppColors.sidebarItemSelected,
            selectedIconTheme: const IconThemeData(
              color: AppColors.sidebarIndicator,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AppColors.textOnDarkMuted,
            ),
            selectedLabelTextStyle: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDark,
            ),
            unselectedLabelTextStyle: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textOnDarkMuted,
            ),
            leading: const _RailLeading(),
            trailing: _RailTrailing(),
            trailingAtBottom: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.data_object_rounded),
                label: Text('API 提取'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                label: Text('知识库'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description_outlined),
                label: Text('文档列表'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.upload_file_outlined),
                label: Text('批量创建'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_tree_outlined),
                label: Text('目录更新'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          const Expanded(child: _ContentArea()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rail header: logo icon + app name
// ---------------------------------------------------------------------------

class _RailLeading extends StatelessWidget {
  const _RailLeading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 16.h, 0, 12.h),
      child: Column(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppColors.sidebarIndicator,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.grain, color: Colors.white, size: 18.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            'DotNest',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rail footer: settings button + version label
// ---------------------------------------------------------------------------

class _RailTrailing extends StatelessWidget {
  const _RailTrailing();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NavigationViewModel>();
    final onSettings = vm.currentPage == NavPage.settings;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '设置',
            child: InkWell(
              onTap: () => vm.navigateTo(NavPage.settings),
              borderRadius: BorderRadius.circular(8.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: onSettings
                      ? AppColors.sidebarItemSelected
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  size: 20.sp,
                  color: onSettings
                      ? AppColors.sidebarIndicator
                      : AppColors.textOnDarkMuted,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'v0.1.0',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textOnDarkMuted.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content area: switches pages based on NavigationViewModel.currentPage
// ---------------------------------------------------------------------------

class _ContentArea extends StatelessWidget {
  const _ContentArea();

  @override
  Widget build(BuildContext context) {
    final currentPage = context.select<NavigationViewModel, NavPage>(
      (vm) => vm.currentPage,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (currentPage) {
        NavPage.extract => const ExtractPage(key: ValueKey('extract')),
        NavPage.yuqueRepos => const RepoListPage(key: ValueKey('yuqueRepos')),
        NavPage.yuqueDocs => const DocListPage(key: ValueKey('yuqueDocs')),
        NavPage.yuqueBatchUpload => const BatchUploadPage(
          key: ValueKey('yuqueBatchUpload'),
        ),
        NavPage.yuqueTocUpdate => const TocUpdatePage(
          key: ValueKey('yuqueTocUpdate'),
        ),
        NavPage.settings => const SettingsPage(key: ValueKey('settings')),
      },
    );
  }
}
