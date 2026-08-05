import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../model/reclassify_result.dart';
import '../viewmodel/reclassify_viewmodel.dart';

class ReclassifyPage extends StatelessWidget {
  const ReclassifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReclassifyViewModel(),
      child: const _ReclassifyPageContent(),
    );
  }
}

class _ReclassifyPageContent extends StatelessWidget {
  const _ReclassifyPageContent();

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return const SingleChildScrollView(
                    child: Column(
                      children: [
                        _ConfigPanel(),
                        _ResultPanel(),
                      ],
                    ),
                  );
                }
                return Row(
                  children: [
                    SizedBox(
                      width: 380.w,
                      child: const _ConfigPanel(),
                    ),
                    Expanded(child: const _ResultPanel()),
                  ],
                );
              },
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
              Icons.category_rounded,
              size: 24.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '调整分类',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '按 YAML 配置规则，将目录下的 .md 文件重新分组到新的目录结构',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
    final vm = context.watch<ReclassifyViewModel>();

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
            value: vm.sourceDir,
            icon: Icons.folder_open_rounded,
            onTap: () => context.read<ReclassifyViewModel>().pickSourceDir(),
          ),
          SizedBox(height: 16.h),

          _PickerField(
            label: '分类配置文件',
            hint: '自动查找 *_api_list.yaml',
            value: vm.configPath,
            icon: Icons.data_object_outlined,
            onTap: vm.sourceDir == null
                ? null
                : () => context
                      .read<ReclassifyViewModel>()
                      .pickConfigFileManually(),
          ),

          if (vm.errorMessage != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
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
            onPressed: (vm.isProcessing || !vm.isReadyToRun)
                ? null
                : () => _confirmAndRun(context, vm),
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
              vm.isProcessing ? '处理中...' : '开始分类',
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
              onPressed: () => context.read<ReclassifyViewModel>().reset(),
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

  Future<void> _confirmAndRun(
    BuildContext context,
    ReclassifyViewModel vm,
  ) async {
    final count = vm.pendingMdFileCount ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(fileCount: count),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<ReclassifyViewModel>().startReclassify();
  }
}

class _ConfirmDialog extends StatelessWidget {
  final int fileCount;
  const _ConfirmDialog({required this.fileCount});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text('确认调整分类', style: TextStyle(fontSize: 15.sp)),
      content: Text(
        '即将对目标目录下的 $fileCount 个 .md 文件进行重新分类，是否继续？',
        style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('取消', style: TextStyle(fontSize: 13.sp)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text('开始分类', style: TextStyle(fontSize: 13.sp)),
        ),
      ],
    );
  }
}

class _PickerField extends StatefulWidget {
  final String label;
  final String hint;
  final String? value;
  final IconData icon;
  final VoidCallback? onTap;

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
    final vm = context.watch<ReclassifyViewModel>();

    if (vm.isProcessing) {
      return const Center(child: _ProcessingPlaceholder());
    }

    if (!vm.done) {
      return const Center(child: _EmptyPlaceholder());
    }

    final outcome = vm.outcome!;
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
          _StatsBar(stats: outcome.stats),
          Divider(height: 1, color: AppColors.cardBorder),
          Expanded(child: _WarningList(warnings: outcome.warnings)),
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
          '正在调整分类...',
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
            Icons.category_rounded,
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
          '配置目标目录和分类配置文件后，点击"开始分类"',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  final ReclassifyStats stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _StatCard(
            label: '已分类',
            count: stats.movedFiles,
            color: AppColors.success,
            icon: Icons.check_circle_rounded,
          ),
          _StatCard(
            label: '缺少 title',
            count: stats.missingTitleFiles,
            color: AppColors.warning,
            icon: Icons.warning_amber_rounded,
          ),
          _StatCard(
            label: '未匹配分类',
            count: stats.unmatchedFiles,
            color: AppColors.error,
            icon: Icons.error_rounded,
          ),
          _StatCard(
            label: '合计',
            count: stats.totalFiles,
            color: AppColors.info,
            icon: Icons.insert_drive_file_rounded,
          ),
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

class _WarningList extends StatelessWidget {
  final List<ReclassifyWarning> warnings;

  const _WarningList({required this.warnings});

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 48.sp,
                color: AppColors.success,
              ),
              SizedBox(height: 12.h),
              Text(
                '全部文件均已成功分类，无警告',
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(20.w),
      itemCount: warnings.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final warning = warnings[index];
        return _WarningItem(warning: warning);
      },
    );
  }
}

class _WarningItem extends StatefulWidget {
  final ReclassifyWarning warning;

  const _WarningItem({required this.warning});

  @override
  State<_WarningItem> createState() => _WarningItemState();
}

class _WarningItemState extends State<_WarningItem> {
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
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 18.sp,
                color: AppColors.warning,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: Text(
                widget.warning.relativePath,
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
                widget.warning.message,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
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
