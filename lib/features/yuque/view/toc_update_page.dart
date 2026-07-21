import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodel/yuque_viewmodel.dart';

/// 目录更新子页面 —— 选择一个 .md 文件，将其原始内容作为 toc 更新至语雀知识库
class TocUpdatePage extends StatefulWidget {
  const TocUpdatePage({super.key});

  @override
  State<TocUpdatePage> createState() => _TocUpdatePageState();
}

class _TocUpdatePageState extends State<TocUpdatePage> {
  late final TextEditingController _bookIdCtrl;

  @override
  void initState() {
    super.initState();
    _bookIdCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<YuqueViewModel>();
      if (_bookIdCtrl.text.isEmpty && vm.tocBookId.isNotEmpty) {
        _bookIdCtrl.text = vm.tocBookId;
      }
    });
  }

  @override
  void dispose() {
    _bookIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<YuqueViewModel>(
      builder: (context, vm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TocActionBar(vm: vm, bookIdCtrl: _bookIdCtrl),
            if (vm.tocErrorMessage != null)
              _ErrorBanner(message: vm.tocErrorMessage!),
            if (vm.tocUpdated) const _SuccessBanner(),
            Expanded(
              child: vm.tocRawContent == null
                  ? const _TocEmptyState()
                  : _TocPreviewBody(vm: vm),
            ),
          ],
        );
      },
    );
  }
}

// ── 操作栏 ────────────────────────────────────────────────────────────────────

class _TocActionBar extends StatelessWidget {
  final YuqueViewModel vm;
  final TextEditingController bookIdCtrl;
  const _TocActionBar({required this.vm, required this.bookIdCtrl});

  @override
  Widget build(BuildContext context) {
    final hasFile = vm.tocRawContent != null;
    final isUpdating = vm.isTocUpdating;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Row(
        children: [
          // 文件名展示
          if (hasFile) ...[
            Icon(
              Icons.description_outlined,
              size: 14.sp,
              color: AppColors.sidebarIndicator,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                vm.tocFileName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ] else ...[
            Text(
              '目录更新',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 12.w),
          ],
          // 选择文件
          OutlinedButton.icon(
            onPressed: isUpdating ? null : () => vm.pickTocFile(),
            icon: Icon(Icons.file_open_outlined, size: 15.sp),
            label: Text(
              hasFile ? '重新选择' : '选择 .md 文件',
              style: TextStyle(fontSize: 13.sp),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.sidebarIndicator,
              side: BorderSide(
                color: AppColors.sidebarIndicator.withValues(alpha: 0.5),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          if (hasFile) ...[
            SizedBox(width: 6.w),
            TextButton(
              onPressed: isUpdating ? null : vm.clearTocFile,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              ),
              child: Text('清除', style: TextStyle(fontSize: 13.sp)),
            ),
          ],
          const Spacer(),
          // 知识库 ID
          SizedBox(
            width: 160.w,
            child: TextField(
              controller: bookIdCtrl,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '知识库 ID',
                hintStyle: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 8.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: AppColors.sidebarIndicator,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: AppColors.contentBg,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // 更新目录
          FilledButton.icon(
            onPressed: (isUpdating || !hasFile)
                ? null
                : () => vm.updateToc(bookIdCtrl.text),
            icon: isUpdating
                ? SizedBox(
                    width: 14.r,
                    height: 14.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.sync_outlined, size: 15.sp),
            label: Text(
              isUpdating ? '更新中...' : '更新目录',
              style: TextStyle(fontSize: 13.sp),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sidebarIndicator,
              disabledBackgroundColor: AppColors.sidebarIndicator.withValues(
                alpha: 0.4,
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 通知横幅 ──────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 15.sp,
            color: Colors.red.shade500,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13.sp, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 15.sp,
            color: Colors.green.shade600,
          ),
          SizedBox(width: 8.w),
          Text(
            '目录更新成功',
            style: TextStyle(fontSize: 13.sp, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }
}

// ── 空状态 ────────────────────────────────────────────────────────────────────

class _TocEmptyState extends StatelessWidget {
  const _TocEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.toc_outlined,
            size: 44.sp,
            color: AppColors.sidebarIndicator.withValues(alpha: 0.35),
          ),
          SizedBox(height: 14.h),
          Text(
            '选择一个 .md 文件，将其内容作为目录提交',
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── 内容预览 ──────────────────────────────────────────────────────────────────

class _TocPreviewBody extends StatelessWidget {
  final YuqueViewModel vm;
  const _TocPreviewBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.contentBg,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Text(
                '文件内容预览',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.r),
                child: SelectableText(
                  vm.tocRawContent ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
