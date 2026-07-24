import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../model/md_file_item.dart';
import '../model/scan_group_node.dart';
import '../model/upload_result.dart';
import '../viewmodel/yuque_viewmodel.dart';

/// 批量文档创建子页面 —— 选择文件夹后递归扫描 .md 文件，批量上传至语雀知识库
class BatchUploadPage extends StatefulWidget {
  const BatchUploadPage({super.key});

  @override
  State<BatchUploadPage> createState() => _BatchUploadPageState();
}

class _BatchUploadPageState extends State<BatchUploadPage> {
  late final TextEditingController _bookIdCtrl;

  @override
  void initState() {
    super.initState();
    _bookIdCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<YuqueViewModel>();
      if (_bookIdCtrl.text.isEmpty && vm.batchBookId.isNotEmpty) {
        _bookIdCtrl.text = vm.batchBookId;
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
            _BatchActionBar(vm: vm, bookIdCtrl: _bookIdCtrl),
            Expanded(child: _BatchContentBody(vm: vm)),
          ],
        );
      },
    );
  }
}

// ── 操作栏 ────────────────────────────────────────────────────────────────────

Future<void> _exportGroupedMarkdown(
  BuildContext context,
  YuqueViewModel vm,
) async {
  final savedPath = await vm.exportGroupedMarkdown();
  if (!context.mounted || savedPath == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('已导出至：$savedPath', style: TextStyle(fontSize: 13.sp)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      width: 420.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    ),
  );
}

class _BatchActionBar extends StatelessWidget {
  final YuqueViewModel vm;
  final TextEditingController bookIdCtrl;
  const _BatchActionBar({required this.vm, required this.bookIdCtrl});

  String get _folderLabel {
    final path = vm.batchFolderPath;
    if (path == null || path.isEmpty) return '未选择文件夹';
    // 只显示末尾两段路径，避免过长
    final parts = path.replaceAll('\\', '/').split('/');
    if (parts.length <= 2) return path;
    return '.../${parts[parts.length - 2]}/${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final hasFiles = vm.scannedFiles.isNotEmpty;
    final isUploading = vm.isBatchUploading;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Row(
        children: [
          // 文件夹路径展示
          Expanded(
            child: Container(
              height: 36.h,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: AppColors.contentBg,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                _folderLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: vm.batchFolderPath != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // 选择文件夹
          OutlinedButton.icon(
            onPressed: isUploading ? null : () => vm.pickBatchFolder(),
            icon: Icon(Icons.folder_open_outlined, size: 15.sp),
            label: Text('选择文件夹', style: TextStyle(fontSize: 13.sp)),
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
          SizedBox(width: 8.w),
          // 导出目录
          OutlinedButton.icon(
            onPressed: (isUploading || !hasFiles)
                ? null
                : () => _exportGroupedMarkdown(context, vm),
            icon: Icon(Icons.download_outlined, size: 15.sp),
            label: Text('导出目录', style: TextStyle(fontSize: 13.sp)),
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
          SizedBox(width: 16.w),
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
          // 开始上传
          FilledButton.icon(
            onPressed: (isUploading || !hasFiles)
                ? null
                : () => vm.startBatchUpload(bookIdCtrl.text),
            icon: isUploading
                ? SizedBox(
                    width: 14.r,
                    height: 14.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.upload_outlined, size: 15.sp),
            label: Text(
              isUploading
                  ? '上传中 ${vm.batchUploadedCount}/${vm.scannedFiles.length}'
                  : '开始上传',
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

// ── 内容区 ────────────────────────────────────────────────────────────────────

class _BatchContentBody extends StatelessWidget {
  final YuqueViewModel vm;
  const _BatchContentBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    // 错误状态
    if (vm.batchErrorMessage != null && vm.scannedFiles.isEmpty) {
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
              vm.batchErrorMessage!,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    // 空状态
    if (vm.scannedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 44.sp,
              color: AppColors.sidebarIndicator.withValues(alpha: 0.35),
            ),
            SizedBox(height: 14.h),
            Text(
              '选择文件夹后将自动扫描其中的 .md 文件',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 上传结果表格（上传中 / 上传完成）
    if (vm.isBatchUploading || vm.uploadResults.isNotEmpty) {
      return _UploadResultTable(vm: vm);
    }

    // 扫描预览表格（已扫描，尚未上传）
    return _ScanPreviewTable(vm: vm);
  }
}

// ── 扫描预览表格 ───────────────────────────────────────────────────────────────

/// 扁平化后的一行：分组标题行或文件行
sealed class _ScanRow {
  final int depth;
  const _ScanRow(this.depth);
}

class _ScanGroupHeaderRow extends _ScanRow {
  final ScanGroupNode node;
  const _ScanGroupHeaderRow(this.node, int depth) : super(depth);
}

class _ScanFileRow extends _ScanRow {
  final MdFileItem file;
  const _ScanFileRow(this.file, int depth) : super(depth);
}

/// 依据分组树与折叠状态，展开为可直接渲染的行列表
List<_ScanRow> _flattenScanRows(YuqueViewModel vm) {
  final tree = vm.scanGroupTree;
  final rows = <_ScanRow>[
    for (final file in tree.rootFiles) _ScanFileRow(file, 0),
  ];

  void visit(ScanGroupNode node, int depth) {
    rows.add(_ScanGroupHeaderRow(node, depth));
    if (vm.isGroupCollapsed(node.path)) return;
    for (final file in node.files) {
      rows.add(_ScanFileRow(file, depth + 1));
    }
    for (final child in node.children) {
      visit(child, depth + 1);
    }
  }

  for (final group in tree.groups) {
    visit(group, 0);
  }
  return rows;
}

class _ScanPreviewTable extends StatelessWidget {
  final YuqueViewModel vm;
  const _ScanPreviewTable({required this.vm});

  @override
  Widget build(BuildContext context) {
    final rows = _flattenScanRows(vm);
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
          children: [
            _ScanPreviewHeader(count: vm.scannedFiles.length),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withValues(alpha: 0.04),
                ),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return switch (row) {
                    _ScanGroupHeaderRow() => _ScanGroupHeader(
                      vm: vm,
                      node: row.node,
                      depth: row.depth,
                    ),
                    _ScanFileRow() => _ScanPreviewRow(
                      file: row.file,
                      depth: row.depth,
                      index: index,
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分组标题行：可点击展开/折叠，按 depth 缩进以保留原有层级
class _ScanGroupHeader extends StatelessWidget {
  final YuqueViewModel vm;
  final ScanGroupNode node;
  final int depth;
  const _ScanGroupHeader({
    required this.vm,
    required this.node,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final collapsed = vm.isGroupCollapsed(node.path);
    return InkWell(
      onTap: () => vm.toggleGroupCollapsed(node.path),
      child: Container(
        color: AppColors.contentBg.withValues(alpha: 0.7),
        padding: EdgeInsets.only(
          left: 16.w + depth * 18.w,
          right: 16.w,
          top: 9.h,
          bottom: 9.h,
        ),
        child: Row(
          children: [
            Icon(
              collapsed
                  ? Icons.chevron_right_rounded
                  : Icons.expand_more_rounded,
              size: 16.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.folder_outlined,
              size: 14.sp,
              color: AppColors.sidebarIndicator.withValues(alpha: 0.8),
            ),
            SizedBox(width: 6.w),
            Text(
              node.name,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '${node.totalFileCount} 个文件',
              style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPreviewHeader extends StatelessWidget {
  final int count;
  const _ScanPreviewHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.contentBg,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerCell('文件名')),
          Expanded(flex: 3, child: _headerCell('slug')),
          Expanded(flex: 4, child: _headerCell('title')),
          SizedBox(
            width: 80.w,
            child: Text(
              '共 $count 个文件',
              style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.right,
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

class _ScanPreviewRow extends StatefulWidget {
  final MdFileItem file;
  final int depth;
  final int index;
  const _ScanPreviewRow({
    required this.file,
    required this.depth,
    required this.index,
  });

  @override
  State<_ScanPreviewRow> createState() => _ScanPreviewRowState();
}

class _ScanPreviewRowState extends State<_ScanPreviewRow> {
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
        padding: EdgeInsets.only(
          left: 16.w + widget.depth * 18.w,
          right: 16.w,
          top: 11.h,
          bottom: 11.h,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                widget.file.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.file.slug,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                widget.file.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary),
              ),
            ),
            SizedBox(width: 80.w),
          ],
        ),
      ),
    );
  }
}

// ── 上传结果表格 ───────────────────────────────────────────────────────────────

class _UploadResultTable extends StatelessWidget {
  final YuqueViewModel vm;
  const _UploadResultTable({required this.vm});

  @override
  Widget build(BuildContext context) {
    final total = vm.scannedFiles.length;
    final doneCount = vm.uploadResults.length;
    final successCount = vm.uploadResults.where((r) => r.success).length;
    final failCount = doneCount - successCount;

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
          children: [
            _UploadResultHeader(
              total: total,
              done: doneCount,
              success: successCount,
              fail: failCount,
              isUploading: vm.isBatchUploading,
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: total,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withValues(alpha: 0.04),
                ),
                itemBuilder: (context, index) {
                  final file = vm.scannedFiles[index];
                  final result = index < vm.uploadResults.length
                      ? vm.uploadResults[index]
                      : null;
                  final isCurrent =
                      vm.isBatchUploading && index == vm.uploadResults.length;
                  return _UploadResultRow(
                    file: file,
                    result: result,
                    isCurrent: isCurrent,
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadResultHeader extends StatelessWidget {
  final int total;
  final int done;
  final int success;
  final int fail;
  final bool isUploading;
  const _UploadResultHeader({
    required this.total,
    required this.done,
    required this.success,
    required this.fail,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.contentBg,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerCell('文件名')),
          Expanded(flex: 3, child: _headerCell('slug')),
          Expanded(flex: 3, child: _headerCell('状态')),
          SizedBox(
            width: 160.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (success > 0) ...[
                  Icon(
                    Icons.check_circle_outline,
                    size: 12.sp,
                    color: Colors.green.shade600,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '$success',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.green.shade600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                if (fail > 0) ...[
                  Icon(
                    Icons.cancel_outlined,
                    size: 12.sp,
                    color: Colors.red.shade400,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '$fail',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.red.shade400,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  isUploading ? '$done / $total' : '共 $total',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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

class _UploadResultRow extends StatefulWidget {
  final MdFileItem file;
  final UploadResult? result;
  final bool isCurrent;
  final int index;
  const _UploadResultRow({
    required this.file,
    required this.result,
    required this.isCurrent,
    required this.index,
  });

  @override
  State<_UploadResultRow> createState() => _UploadResultRowState();
}

class _UploadResultRowState extends State<_UploadResultRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
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
                widget.file.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.file.slug,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _StatusCell(result: result, isCurrent: widget.isCurrent),
            ),
            SizedBox(width: 160.w),
          ],
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final UploadResult? result;
  final bool isCurrent;
  const _StatusCell({required this.result, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return Row(
        children: [
          SizedBox(
            width: 12.r,
            height: 12.r,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.sidebarIndicator,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            '上传中...',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.sidebarIndicator,
            ),
          ),
        ],
      );
    }
    final r = result;
    if (r == null) {
      return Text(
        '待上传',
        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
      );
    }
    if (r.success) {
      return Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 13.sp,
            color: Colors.green.shade600,
          ),
          SizedBox(width: 5.w),
          Text(
            '成功',
            style: TextStyle(fontSize: 12.sp, color: Colors.green.shade600),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.cancel_outlined, size: 13.sp, color: Colors.red.shade400),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(
            r.error ?? '失败',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.sp, color: Colors.red.shade400),
          ),
        ),
      ],
    );
  }
}
