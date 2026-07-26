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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.contentBg,
            AppColors.contentBg.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          const _PageHeader(),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 380.w,
                  child: const _ConfigPanel(),
                ),
                Expanded(child: const _ResultPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 页面头部 ──────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.code_rounded,
              size: 24.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API 提取',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '从 Dart 项目源码提取 API 文档注释，生成 Markdown 文件',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
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
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [AppColors.shadowMd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20.sp,
                color: AppColors.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                '配置',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          _DirPickerField(
            label: '源码目录',
            hint: '选择 Dart 项目目录',
            value: vm.sourceDir,
            icon: Icons.folder_open_rounded,
            onTap: () => context.read<ExtractViewModel>().pickSourceDir(),
          ),
          SizedBox(height: 16.h),

          _DirPickerField(
            label: '输出目录',
            hint: '选择 Markdown 文件输出目录',
            value: vm.outputDir,
            icon: Icons.drive_folder_upload_rounded,
            onTap: () => context.read<ExtractViewModel>().pickOutputDir(),
          ),

          if (vm.errorMessage != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      vm.errorMessage!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          FilledButton.icon(
            onPressed: vm.isExtracting
                ? null
                : () => context.read<ExtractViewModel>().startExtract(),
            icon: vm.isExtracting
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.play_arrow_rounded, size: 20.sp),
            label: Text(
              vm.isExtracting ? '提取中...' : '开始提取',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),

          if (vm.done) ...[
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: () => context.read<ExtractViewModel>().reset(),
              icon: Icon(Icons.refresh_rounded, size: 18.sp),
              label: Text(
                '重置',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
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

class _DirPickerField extends StatefulWidget {
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
  State<_DirPickerField> createState() => _DirPickerFieldState();
}

class _DirPickerFieldState extends State<_DirPickerField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.primaryContainer.withValues(alpha: 0.5)
                    : AppColors.contentBg,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: widget.value != null
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : _isHovered
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.cardBorder,
                  width: _isHovered ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 18.sp,
                    color: widget.value != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.value ?? widget.hint,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: widget.value != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: widget.value != null
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18.sp,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
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

    return Container(
      margin: EdgeInsets.fromLTRB(0, 20.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [AppColors.shadowMd],
      ),
      child: Column(
        children: [
          if (vm.stats != null) _StatsBar(stats: vm.stats!),
          if (vm.stats != null)
            Divider(height: 1, color: AppColors.cardBorder),
          Expanded(
            child: _ResultList(results: vm.results),
          ),
        ],
      ),
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
          width: 48.w,
          height: 48.w,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          '正在分析源码...',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '请稍候，这可能需要几秒钟',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
          ),
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
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.description_outlined,
            size: 48.sp,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          '准备开始',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '配置源码目录和输出目录后，点击"开始提取"',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
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
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          _StatCard(
            label: '成功',
            count: stats.generatedDocs,
            color: AppColors.success,
            icon: Icons.check_circle_rounded,
          ),
          SizedBox(width: 12.w),
          _StatCard(
            label: '失败',
            count: stats.errors,
            color: AppColors.error,
            icon: Icons.error_rounded,
          ),
          SizedBox(width: 12.w),
          _StatCard(
            label: '合计',
            count: stats.totalFiles,
            color: AppColors.info,
            icon: Icons.insert_drive_file_rounded,
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16.sp,
                  color: AppColors.success,
                ),
                SizedBox(width: 6.w),
                Text(
                  '提取完成',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
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
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 48.sp,
                color: AppColors.textTertiary,
              ),
              SizedBox(height: 12.h),
              Text(
                '未找到任何包含文档注释的公开 API',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(20.w),
      itemCount: results.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final result = results[index];
        return _ResultItem(result: result);
      },
    );
  }
}

class _ResultItem extends StatefulWidget {
  final ExtractResult result;

  const _ResultItem({required this.result});

  @override
  State<_ResultItem> createState() => _ResultItemState();
}

class _ResultItemState extends State<_ResultItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.primaryContainer.withValues(alpha: 0.3)
              : AppColors.contentBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: widget.result.success
                ? _isHovered
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.cardBorder
                : AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: widget.result.success
                    ? AppColors.successLight
                    : AppColors.errorLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                widget.result.success
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                size: 18.sp,
                color:
                    widget.result.success ? AppColors.success : AppColors.error,
              ),
            ),
            SizedBox(width: 12.w),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                widget.result.apiType.keyword,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(width: 12.w),

            Expanded(
              child: Text(
                widget.result.apiName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            Expanded(
              child: Text(
                widget.result.success
                    ? widget.result.fileName
                    : (widget.result.error ?? '未知错误'),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: widget.result.success
                      ? AppColors.textSecondary
                      : AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
