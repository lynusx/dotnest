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
import 'widgets/sidebar_nav_item.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _Sidebar(),
          const _ResizeHandle(),
          Expanded(child: const _ContentArea()),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NavigationViewModel>();
    final current = vm.currentPage;

    return Container(
      width: vm.sidebarWidth.w,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // logo area
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 20.h),
            child: Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: AppColors.sidebarIndicator,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(Icons.grain, color: Colors.white, size: 16.sp),
                ),
                SizedBox(width: 10.w),
                Text(
                  'DotNest',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withValues(alpha: 0.07),
            indent: 16.w,
            endIndent: 16.w,
          ),

          SizedBox(height: 12.h),

          // API 提取
          SidebarNavItem(
            icon: Icons.data_object_rounded,
            label: 'API 提取',
            selected: current == NavPage.extract,
            onTap: () => vm.navigateTo(NavPage.extract),
          ),

          // 语雀同步 group header
          SidebarNavItem(
            icon: Icons.cloud_sync_rounded,
            label: '语雀同步',
            selected: current.isYuquePage,
            onTap: () => vm.navigateTo(NavPage.yuqueRepos),
          ),

          // Yuque sub-items (always visible)
          SidebarSubNavItem(
            label: '知识库列表',
            selected: current == NavPage.yuqueRepos,
            onTap: () => vm.navigateTo(NavPage.yuqueRepos),
          ),
          SidebarSubNavItem(
            label: '文档列表',
            selected: current == NavPage.yuqueDocs,
            onTap: () => vm.navigateTo(NavPage.yuqueDocs),
          ),
          SidebarSubNavItem(
            label: '批量创建',
            selected: current == NavPage.yuqueBatchUpload,
            onTap: () => vm.navigateTo(NavPage.yuqueBatchUpload),
          ),
          SidebarSubNavItem(
            label: '目录更新',
            selected: current == NavPage.yuqueTocUpdate,
            onTap: () => vm.navigateTo(NavPage.yuqueTocUpdate),
          ),

          const Spacer(),

          // version
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Text(
              'v0.1.0',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textOnDarkMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        NavPage.yuqueBatchUpload =>
          const BatchUploadPage(key: ValueKey('yuqueBatchUpload')),
        NavPage.yuqueTocUpdate =>
          const TocUpdatePage(key: ValueKey('yuqueTocUpdate')),
      },
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle();

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hovering = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<NavigationViewModel>();
    final active = _hovering || _dragging;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (details) {
          final designDelta = details.delta.dx / ScreenUtil().scaleWidth;
          vm.setSidebarWidth(vm.sidebarWidth + designDelta);
        },
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 5,
          color: active
              ? AppColors.sidebarIndicator.withValues(alpha: 0.25)
              : Colors.transparent,
        ),
      ),
    );
  }
}
