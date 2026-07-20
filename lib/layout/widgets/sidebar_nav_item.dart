import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';

class SidebarNavItem extends StatefulWidget {
  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

// ---------------------------------------------------------------------------
// Second-level sub-navigation item (used for Yuque sub-pages in sidebar)
// ---------------------------------------------------------------------------

class SidebarSubNavItem extends StatefulWidget {
  const SidebarSubNavItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<SidebarSubNavItem> createState() => _SidebarSubNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.sidebarItemSelected
        : _hovering
        ? AppColors.sidebarItemHover
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              // selected indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3.w,
                height: 18.h,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppColors.sidebarIndicator
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                widget.icon,
                size: 18.sp,
                color: widget.selected
                    ? AppColors.textOnDark
                    : AppColors.textOnDarkMuted,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.selected
                        ? AppColors.textOnDark
                        : AppColors.textOnDarkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarSubNavItemState extends State<SidebarSubNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.sidebarItemSelected
        : _hovering
        ? AppColors.sidebarItemHover
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          padding: EdgeInsets.fromLTRB(36.w, 8.h, 12.w, 8.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 4.w,
                height: 4.w,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppColors.sidebarIndicator
                      : AppColors.textOnDarkMuted.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: widget.selected
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: widget.selected
                        ? AppColors.textOnDark
                        : AppColors.textOnDarkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
