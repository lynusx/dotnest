import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../model/extract_result.dart';
import '../viewmodel/extract_viewmodel.dart';

class ExtractPage extends StatelessWidget {
  const ExtractPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExtractViewModel(),
      child: const _ExtractPageContent(),
    );
  }
}

class _ExtractPageContent extends StatelessWidget {
  const _ExtractPageContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.contentBg,
      child: Row(
        children: [
          // 左侧配置面板
          SizedBox(
            width: 320.w,
            child: const _ConfigPanel(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // 右侧结果面板
          const Expanded(child: _ResultPanel()),
        ],
      ),
    );
  }
}

// ── 左侧配置面板 ──────────────────────────────────────────────────────────────

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExtractViewModel>();

    return Container(
      color: AppColors.contentBg,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'API 提取配置',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '从 Dart 项目源码提取 API 文档注释，生成 Markdown 文件',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 24.h),

          // 源码目录
          _DirPickerField(
            label: '源码目录',
            hint: '选择 Dart 项目目录',
            value: vm.sourceDir,
            icon: Icons.folder_open_outlined,
            onTap: () => context.read<ExtractViewModel>().pickSourceDir(),
          ),
          SizedBox(height: 16.h),

          // 输出目录
          _DirPickerField(
            label: '输出目录',
            hint: '选择 Markdown 文件输出目录',
            value: vm.outputDir,
            icon: Icons.drive_folder_upload_outlined,
            onTap: () => context.read<ExtractViewModel>().pickOutputDir(),
          ),
          SizedBox(height: 8.h),

          // 错误提示
          if (vm.errorMessage != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                vm.errorMessage!,
                style: TextStyle(fontSize: 12.sp, color: Colors.red.shade700),
              ),
            ),
          ],

          const Spacer(),

          // 开始提取按钮
          FilledButton.icon(
            onPressed: vm.isExtracting
                ? null
                : () => context.read<ExtractViewModel>().startExtract(),
            icon: vm.isExtracting
                ? SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.play_arrow_rounded, size: 18.sp),
            label: Text(
              vm.isExtracting ? '提取中...' : '开始提取',
              style: TextStyle(fontSize: 13.sp),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sidebarIndicator,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),

          if (vm.done) ...[
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: () => context.read<ExtractViewModel>().reset(),
              icon: Icon(Icons.refresh_rounded, size: 16.sp),
              label: Text('重置', style: TextStyle(fontSize: 13.sp)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 目录选择字段 ──────────────────────────────────────────────────────────────

class _DirPickerField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  const _DirPickerField({
    required this.label,
    required this.hint,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: value != null
                    ? AppColors.sidebarIndicator.withValues(alpha: 0.4)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16.sp,
                  color: value != null
                      ? AppColors.sidebarIndicator
                      : AppColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 右侧结果面板 ──────────────────────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  const _ResultPanel();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExtractViewModel>();

    if (vm.isExtracting) {
      return const Center(child: _ExtractingPlaceholder());
    }

    if (!vm.done && vm.results.isEmpty) {
      return const Center(child: _EmptyPlaceholder());
    }

    return Column(
      children: [
        if (vm.stats != null) _StatsBar(stats: vm.stats!),
        const Divider(height: 1),
        Expanded(
          child: _ResultList(results: vm.results),
        ),
      ],
    );
  }
}

// ── 提取中占位 ────────────────────────────────────────────────────────────────

class _ExtractingPlaceholder extends StatelessWidget {
  const _ExtractingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40.w,
          height: 40.w,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.sidebarIndicator,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          '正在分析源码，请稍候...',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── 空状态占位 ────────────────────────────────────────────────────────────────

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.description_outlined,
          size: 48.sp,
          color: AppColors.sidebarIndicator.withValues(alpha: 0.4),
        ),
        SizedBox(height: 16.h),
        Text(
          '配置源码目录和输出目录后，点击"开始提取"',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── 统计栏 ────────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final ExtractStats stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      color: AppColors.cardBg,
      child: Row(
        children: [
          _StatChip(
            label: '成功',
            count: stats.generatedDocs,
            color: Colors.green.shade600,
          ),
          SizedBox(width: 16.w),
          _StatChip(
            label: '失败',
            count: stats.errors,
            color: Colors.red.shade600,
          ),
          SizedBox(width: 16.w),
          _StatChip(
            label: '合计',
            count: stats.totalFiles,
            color: AppColors.textSecondary,
          ),
          const Spacer(),
          Icon(
            Icons.check_circle_outline_rounded,
            size: 16.sp,
            color: Colors.green.shade600,
          ),
          SizedBox(width: 4.w),
          Text(
            '提取完成',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── 结果列表 ──────────────────────────────────────────────────────────────────

class _ResultList extends StatelessWidget {
  final List<ExtractResult> results;

  const _ResultList({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Text(
          '未找到任何包含文档注释的公开 API',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: results.length,
      separatorBuilder: (_, _) => SizedBox(height: 4.h),
      itemBuilder: (context, index) {
        final result = results[index];
        return _ResultItem(result: result);
      },
    );
  }
}

class _ResultItem extends StatelessWidget {
  final ExtractResult result;

  const _ResultItem({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: result.success
              ? const Color(0xFFE8E8E8)
              : Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          // 状态图标
          Icon(
            result.success
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            size: 16.sp,
            color: result.success ? Colors.green.shade600 : Colors.red.shade500,
          ),
          SizedBox(width: 10.w),

          // API 类型标签
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.sidebarIndicator.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              result.apiType.keyword,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.sidebarIndicator,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(width: 8.w),

          // API 名称
          Expanded(
            child: Text(
              result.apiName,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // 文件名或错误
          Expanded(
            child: Text(
              result.success
                  ? result.fileName
                  : (result.error ?? '未知错误'),
              style: TextStyle(
                fontSize: 11.sp,
                color: result.success
                    ? AppColors.textSecondary
                    : Colors.red.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
