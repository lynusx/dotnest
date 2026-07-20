import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../features/extract/view/extract_page.dart';
import '../features/yuque/view/yuque_page.dart';
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

          // nav items
          SidebarNavItem(
            icon: Icons.data_object_rounded,
            label: 'API 提取',
            selected: vm.currentPage == NavPage.extract,
            onTap: () => vm.navigateTo(NavPage.extract),
          ),
          SidebarNavItem(
            icon: Icons.cloud_sync_rounded,
            label: '语雀同步',
            selected: vm.currentPage == NavPage.yuque,
            onTap: () => vm.navigateTo(NavPage.yuque),
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
        NavPage.yuque => const YuquePage(key: ValueKey('yuque')),
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
