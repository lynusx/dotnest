import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../features/extract/view/extract_page.dart';
import '../features/yuque/view/repo_list_page.dart';
import '../features/yuque/view/doc_list_page.dart';
import '../features/yuque/view/batch_upload_page.dart';
import '../features/yuque/view/toc_update_page.dart';
import '../features/link_rewrite/view/link_rewrite_page.dart';
import 'viewmodel/navigation_viewmodel.dart';
import '../features/settings/view/settings_page.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _ModernSidebar(),
          Container(
            width: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.cardBorder.withValues(alpha: 0.3),
                  AppColors.cardBorder,
                  AppColors.cardBorder.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          const Expanded(child: _ContentArea()),
        ],
      ),
    );
  }
}

// ── 现代化侧边栏 ──────────────────────────────────────────────────────────────

class _ModernSidebar extends StatelessWidget {
  const _ModernSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240.w,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
      ),
      child: Column(
        children: [
          const _SidebarHeader(),
          SizedBox(height: 24.h),
          const Expanded(child: _SidebarMenu()),
          const _SidebarFooter(),
        ],
      ),
    );
  }
}

// ── 侧边栏头部 ────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DotNest',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnDark,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'API Documentation Tool',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.textOnDarkMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 侧边栏菜单 ────────────────────────────────────────────────────────────────

class _SidebarMenu extends StatelessWidget {
  const _SidebarMenu();

  static const _menuItems = [
    _MenuItem(
      icon: Icons.code_rounded,
      label: 'API 提取',
      page: NavPage.extract,
    ),
    _MenuItem(
      icon: Icons.folder_rounded,
      label: '知识库',
      page: NavPage.yuqueRepos,
    ),
    _MenuItem(
      icon: Icons.description_rounded,
      label: '文档列表',
      page: NavPage.yuqueDocs,
    ),
    _MenuItem(
      icon: Icons.upload_file_rounded,
      label: '批量创建',
      page: NavPage.yuqueBatchUpload,
    ),
    _MenuItem(
      icon: Icons.account_tree_rounded,
      label: '目录更新',
      page: NavPage.yuqueTocUpdate,
    ),
    _MenuItem(
      icon: Icons.link_rounded,
      label: '链接重写',
      page: NavPage.linkRewrite,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NavigationViewModel>();

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      children: _menuItems.map((item) {
        final isSelected = vm.currentPage == item.page;
        return _SidebarMenuItem(
          icon: item.icon,
          label: item.label,
          isSelected: isSelected,
          onTap: () => vm.navigateTo(item.page),
        );
      }).toList(),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final NavPage page;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.page,
  });
}

class _SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.sidebarItemSelected
                  : _isHovered
                      ? AppColors.sidebarItemHover
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 20.sp,
                  color: widget.isSelected
                      ? AppColors.sidebarIndicator
                      : _isHovered
                          ? AppColors.textOnDark
                          : AppColors.textOnDarkMuted,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isSelected
                          ? AppColors.textOnDark
                          : _isHovered
                              ? AppColors.textOnDark
                              : AppColors.textOnDarkMuted,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: AppColors.sidebarIndicator,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sidebarIndicator.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 侧边栏底部 ────────────────────────────────────────────────────────────────

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NavigationViewModel>();
    final isSettingsSelected = vm.currentPage == NavPage.settings;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.textOnDarkMuted.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _SidebarMenuItem(
            icon: Icons.settings_rounded,
            label: '设置',
            isSelected: isSettingsSelected,
            onTap: () => vm.navigateTo(NavPage.settings),
          ),
          SizedBox(height: 12.h),
          Text(
            'v0.1.0',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textOnDarkMuted.withValues(alpha: 0.4),
              letterSpacing: 0.5,
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
        NavPage.linkRewrite => const LinkRewritePage(
          key: ValueKey('linkRewrite'),
        ),
        NavPage.settings => const SettingsPage(key: ValueKey('settings')),
      },
    );
  }
}
