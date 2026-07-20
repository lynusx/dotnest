import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class YuquePage extends StatelessWidget {
  const YuquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.contentBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_sync_rounded,
              size: 48.sp,
              color: AppColors.sidebarIndicator.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              '语雀同步',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '将提取结果同步至语雀知识库',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
