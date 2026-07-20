import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodel/yuque_viewmodel.dart';

/// 知识库列表子页面 —— 渲染三列表格：名称、ID、路径
class RepoListPage extends StatelessWidget {
  const RepoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<YuqueViewModel>(
      builder: (context, vm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActionBar(vm: vm),
            Expanded(child: _TableBody(vm: vm)),
          ],
        );
      },
    );
  }
}

// ── 操作栏 ────────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final YuqueViewModel vm;
  const _ActionBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 12.h),
      child: Row(
        children: [
          Text(
            vm.repos.isEmpty ? '知识库列表' : '共 ${vm.repos.length} 个知识库',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: vm.isLoading
                ? null
                : () => vm.fetchRepos(vm.token, vm.login),
            icon: vm.isLoading
                ? SizedBox(
                    width: 14.r,
                    height: 14.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.cloud_download_outlined, size: 15.sp),
            label: Text(
              vm.isLoading ? '获取中...' : '获取知识库列表',
              style: TextStyle(fontSize: 13.sp),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sidebarIndicator,
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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

// ── 表格区域 ──────────────────────────────────────────────────────────────────

class _TableBody extends StatelessWidget {
  final YuqueViewModel vm;
  const _TableBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36.sp,
              color: Colors.redAccent.withValues(alpha: 0.7),
            ),
            SizedBox(height: 10.h),
            Text(
              vm.errorMessage!,
              style:
                  TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    if (vm.repos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 44.sp,
              color: AppColors.sidebarIndicator.withValues(alpha: 0.35),
            ),
            SizedBox(height: 14.h),
            Text(
              '点击「获取知识库列表」加载数据',
              style: TextStyle(
                  fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
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
          children: [
            _TableHeader(),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: vm.repos.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withValues(alpha: 0.04),
                ),
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

// ── 表头 ──────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.contentBg,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '名称',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 90.w,
            child: Text(
              'ID',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '路径',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 数据行 ────────────────────────────────────────────────────────────────────

class _TableRow extends StatefulWidget {
  final dynamic repo;
  final int index;
  const _TableRow({required this.repo, required this.index});

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hovered
        ? AppColors.sidebarItemHover
        : widget.index.isEven
            ? AppColors.cardBg
            : AppColors.contentBg.withValues(alpha: 0.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: bg,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                widget.repo.name as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(
              width: 90.w,
              child: Text(
                '${widget.repo.id}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.repo.slug as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
