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

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.03),
            AppColors.cardBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // 文件名展示
          if (hasFile) ...[
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 18.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '已选择文件',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    vm.tocFileName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
          ] else ...[
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.toc_outlined,
                size: 18.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              '目录更新',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 12.w),
          ],
          // 选择文件
          OutlinedButton.icon(
            onPressed: isUpdating ? null : () => vm.pickTocFile(),
            icon: Icon(Icons.file_open_outlined, size: 16.sp),
            label: Text(
              hasFile ? '重新选择' : '选择 .md 文件',
              style: TextStyle(fontSize: 13.sp),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          if (hasFile) ...[
            SizedBox(width: 8.w),
            TextButton(
              onPressed: isUpdating ? null : vm.clearTocFile,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: AppColors.contentBg,
              ),
            ),
          ),
          SizedBox(width: 12.w),
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
                : Icon(Icons.sync_outlined, size: 16.sp),
            label: Text(
              isUpdating ? '更新中...' : '更新目录',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 0,
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
      margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 16.sp,
              color: AppColors.error,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
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
      margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 16.sp,
              color: AppColors.success,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '目录更新成功',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
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
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.toc_outlined,
              size: 36.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16.h),
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
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.contentBg,
                  ],
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      Icons.preview_outlined,
                      size: 14.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    '文件内容预览',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.r),
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
