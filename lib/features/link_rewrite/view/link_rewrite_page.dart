import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../model/link_rewrite_result.dart';
import '../viewmodel/link_rewrite_viewmodel.dart';

class LinkRewritePage extends StatelessWidget {
  const LinkRewritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LinkRewriteViewModel(),
      child: const _LinkRewritePageContent(),
    );
  }
}

class _LinkRewritePageContent extends StatelessWidget {
  const _LinkRewritePageContent();

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
              Icons.link_rounded,
              size: 24.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '链接重写',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '将正文中的 [X] 引用按 url_map.json 或本文件 H3 标题替换为链接',
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

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LinkRewriteViewModel>();

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
              Icon(Icons.tune_rounded, size: 20.sp, color: AppColors.primary),
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

          _PickerField(
            label: '目标目录',
            hint: '选择待处理的文件夹',
            value: vm.targetDir,
            icon: Icons.folder_open_rounded,
            onTap: () => context.read<LinkRewriteViewModel>().pickTargetDir(),
          ),
          SizedBox(height: 16.h),

          _PickerField(
            label: 'url_map.json',
            hint: '选择 URL 映射文件',
            value: vm.urlMapPath,
            icon: Icons.data_object_outlined,
            onTap: () => context.read<LinkRewriteViewModel>().pickUrlMapFile(),
          ),
          SizedBox(height: 20.h),

          Text(
            '输出方式',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          SegmentedButton<RewriteOutputMode>(
            segments: [
              ButtonSegment(
                value: RewriteOutputMode.overwrite,
                label: Text('原地覆盖', style: TextStyle(fontSize: 13.sp)),
                icon: Icon(Icons.edit_note_rounded, size: 16.sp),
              ),
              ButtonSegment(
                value: RewriteOutputMode.newDirectory,
                label: Text('输出到新目录', style: TextStyle(fontSize: 13.sp)),
                icon: Icon(Icons.drive_folder_upload_outlined, size: 16.sp),
              ),
            ],
            selected: {vm.mode},
            onSelectionChanged: (s) =>
                context.read<LinkRewriteViewModel>().setMode(s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
          ),

          if (vm.mode == RewriteOutputMode.newDirectory) ...[
            SizedBox(height: 16.h),
            _PickerField(
              label: '输出目录',
              hint: '选择输出目录',
              value: vm.outputDir,
              icon: Icons.drive_file_move_outline,
              onTap: () => context.read<LinkRewriteViewModel>().pickOutputDir(),
            ),
          ],

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
            onPressed: vm.isProcessing
                ? null
                : () => context.read<LinkRewriteViewModel>().startRewrite(),
            icon: vm.isProcessing
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
              vm.isProcessing ? '处理中...' : '开始重写',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
              onPressed: () => context.read<LinkRewriteViewModel>().reset(),
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

class _PickerField extends StatefulWidget {
  final String label;
  final String hint;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.hint,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PickerField> createState() => _PickerFieldState();
}

class _PickerFieldState extends State<_PickerField> {
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

class _ResultPanel extends StatelessWidget {
  const _ResultPanel();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LinkRewriteViewModel>();

    if (vm.isProcessing) {
      return const Center(child: _ProcessingPlaceholder());
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
          Expanded(child: _ResultList(results: vm.results)),
        ],
      ),
    );
  }
}

class _ProcessingPlaceholder extends StatelessWidget {
  const _ProcessingPlaceholder();

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
          '正在扫描并重写...',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '请稍候，这可能需要一些时间',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

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
            Icons.link_rounded,
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
          '配置目标目录和 url_map.json 后，点击"开始重写"',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  final LinkRewriteStats stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          _StatCard(
            label: '已处理',
            count: stats.processedFiles,
            color: AppColors.success,
            icon: Icons.check_circle_rounded,
          ),
          SizedBox(width: 12.w),
          _StatCard(
            label: '失败',
            count: stats.errorFiles,
            color: AppColors.error,
            icon: Icons.error_rounded,
          ),
          SizedBox(width: 12.w),
          _StatCard(
            label: '替换总数',
            count: stats.totalReplacements,
            color: AppColors.primary,
            icon: Icons.swap_horiz_rounded,
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
                  '处理完成',
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

class _ResultList extends StatelessWidget {
  final List<LinkRewriteFileResult> results;

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
                '未在目标目录下找到 .md / .markdown 文件',
                style:
                    TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
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
  final LinkRewriteFileResult result;

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

            Expanded(
              flex: 2,
              child: Text(
                widget.result.relativePath,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Expanded(
              child: Text(
                widget.result.success
                    ? '${widget.result.replacementCount} 处替换'
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
