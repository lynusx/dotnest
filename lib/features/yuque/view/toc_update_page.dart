import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodel/yuque_viewmodel.dart';

/// 目录更新子页面 —— 选择 .md 文件，生成目录 Markdown 后更新至语雀知识库
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
              child: vm.tocFiles.isEmpty
                  ? const _TocEmptyState()
                  : _TocBody(vm: vm),
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
    final hasFiles = vm.tocFiles.isNotEmpty;
    final isUpdating = vm.isTocUpdating;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Row(
        children: [
          // 文件数量标签
          Text(
            hasFiles ? '已选 ${vm.tocFiles.length} 个文件' : '目录更新',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 12.w),
          // 选择文件
          OutlinedButton.icon(
            onPressed: isUpdating ? null : () => vm.pickTocFiles(),
            icon: Icon(Icons.add_outlined, size: 15.sp),
            label: Text('选择 .md 文件', style: TextStyle(fontSize: 13.sp)),
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
          if (hasFiles) ...[
            SizedBox(width: 6.w),
            // 清空
            TextButton(
              onPressed: isUpdating ? null : vm.clearTocFiles,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              ),
              child: Text('清空', style: TextStyle(fontSize: 13.sp)),
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
                hintStyle:
                    TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide:
                      BorderSide(color: AppColors.sidebarIndicator, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.contentBg,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // 更新目录
          FilledButton.icon(
            onPressed: (isUpdating || !hasFiles)
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
              disabledBackgroundColor:
                  AppColors.sidebarIndicator.withValues(alpha: 0.4),
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
          Icon(Icons.error_outline_rounded,
              size: 15.sp, color: Colors.red.shade500),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 13.sp, color: Colors.red.shade700)),
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
          Icon(Icons.check_circle_outline,
              size: 15.sp, color: Colors.green.shade600),
          SizedBox(width: 8.w),
          Text(
            '目录更新成功',
            style: TextStyle(
                fontSize: 13.sp, color: Colors.green.shade700),
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
            '选择 .md 文件后将自动生成目录预览',
            style:
                TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── 主体：文件列表 + 目录预览 ─────────────────────────────────────────────────

class _TocBody extends StatelessWidget {
  final YuqueViewModel vm;
  const _TocBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左：可排序文件列表
          Expanded(
            flex: 3,
            child: _FileListPanel(vm: vm),
          ),
          SizedBox(width: 16.w),
          // 右：目录预览
          Expanded(
            flex: 2,
            child: _TocPreviewPanel(toc: vm.generatedToc),
          ),
        ],
      ),
    );
  }
}

// ── 文件列表面板（可排序 + 删除）─────────────────────────────────────────────

class _FileListPanel extends StatelessWidget {
  final YuqueViewModel vm;
  const _FileListPanel({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // 面板标题栏
          Container(
            color: AppColors.contentBg,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _headerCell('文件名'),
                ),
                Expanded(
                  flex: 3,
                  child: _headerCell('slug'),
                ),
                Expanded(
                  flex: 4,
                  child: _headerCell('title'),
                ),
                SizedBox(width: 32.w),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withValues(alpha: 0.06),
          ),
          // 可拖拽排序列表
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.zero,
              itemCount: vm.tocFiles.length,
              onReorderItem: (oldIndex, newIndex) =>
                  vm.reorderTocFiles(oldIndex, newIndex),
              proxyDecorator: (child, index, animation) => Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(6.r),
                child: child,
              ),
              itemBuilder: (context, index) {
                final file = vm.tocFiles[index];
                return _FileRow(
                  key: ValueKey(file.filePath),
                  file: file,
                  index: index,
                  onRemove: () => vm.removeTocFile(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _FileRow extends StatefulWidget {
  final dynamic file; // MdFileItem
  final int index;
  final VoidCallback onRemove;
  const _FileRow({
    required super.key,
    required this.file,
    required this.index,
    required this.onRemove,
  });

  @override
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                widget.file.fileName as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.file.slug as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.sp, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                widget.file.title as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 12.sp, color: AppColors.textPrimary),
              ),
            ),
            // 删除按钮
            SizedBox(
              width: 32.w,
              child: IconButton(
                onPressed: widget.onRemove,
                icon: Icon(
                  Icons.close_rounded,
                  size: 15.sp,
                  color: AppColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: 24.r,
                  minHeight: 24.r,
                ),
                style: IconButton.styleFrom(
                  hoverColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade400,
                ),
                tooltip: '移除',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 目录预览面板 ──────────────────────────────────────────────────────────────

class _TocPreviewPanel extends StatelessWidget {
  final String toc;
  const _TocPreviewPanel({required this.toc});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // 面板标题
          Container(
            color: AppColors.contentBg,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Text(
              '目录预览',
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
          // Markdown 文本
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: SelectableText(
                toc.isEmpty ? '（暂无内容）' : toc,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: toc.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontFamily: 'monospace',
                  height: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
