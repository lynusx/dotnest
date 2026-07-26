import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodel/yuque_viewmodel.dart';

class RepoListPage extends StatelessWidget {
  const RepoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<YuqueViewModel>(
      builder: (context, vm, _) {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PageHeader(vm: vm),
              Expanded(child: _TableBody(vm: vm)),
            ],
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  final YuqueViewModel vm;
  const _PageHeader({required this.vm});

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
              Icons.folder_rounded,
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
                  '知识库列表',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  vm.repos.isEmpty
                      ? '暂无数据'
                      : '共 ${vm.repos.length} 个知识库',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: vm.isLoading
                ? null
                : () => vm.fetchRepos(vm.token, vm.login),
            icon: vm.isLoading
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.cloud_download_outlined, size: 18.sp),
            label: Text(
              vm.isLoading ? '获取中...' : '获取知识库列表',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableBody extends StatelessWidget {
  final YuqueViewModel vm;
  const _TableBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return Center(
        child: Column(
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
              '正在获取知识库列表...',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(32.w),
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48.sp,
                color: AppColors.error,
              ),
              SizedBox(height: 16.h),
              Text(
                '获取失败',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                vm.errorMessage!,
                style: TextStyle(fontSize: 13.sp, color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (vm.repos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_books_outlined,
                size: 48.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              '暂无数据',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '点击「获取知识库列表」加载数据',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [AppColors.shadowMd],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _TableHeader(),
            Divider(height: 1, color: AppColors.cardBorder),
            Expanded(
              child: ListView.separated(
                itemCount: vm.repos.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.cardBorder.withValues(alpha: 0.5)),
                itemBuilder: (context, index) =>
                    _TableRow(repo: vm.repos[index], index: index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.contentBg.withValues(alpha: 0.5),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '名称',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 100.w,
            child: Text(
              'ID',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '路径',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  final dynamic repo;
  final int index;
  const _TableRow({required this.repo, required this.index});

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 18.sp, color: Colors.white),
            SizedBox(width: 8.w),
            Text('已复制：$text', style: TextStyle(fontSize: 13.sp)),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  Widget _copyable(BuildContext context, String value, Widget child) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: () => _copy(context, value), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered
            ? AppColors.primaryContainer.withValues(alpha: 0.3)
            : widget.index.isEven
                ? AppColors.cardBg
                : AppColors.contentBg.withValues(alpha: 0.3),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _copyable(
                context,
                widget.repo.name as String,
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        widget.repo.name as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 100.w,
              child: _copyable(
                context,
                '${widget.repo.id}',
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${widget.repo.id}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _copyable(
                context,
                widget.repo.slug as String,
                Text(
                  widget.repo.slug as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
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
