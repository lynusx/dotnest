import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../model/yuque_doc.dart';
import '../viewmodel/yuque_viewmodel.dart';

/// 文档列表子页面 —— book_id 输入 + 渲染三列表格：标题、ID、路径
class DocListPage extends StatefulWidget {
  const DocListPage({super.key});

  @override
  State<DocListPage> createState() => _DocListPageState();
}

class _DocListPageState extends State<DocListPage> {
  late final TextEditingController _bookIdCtrl;

  @override
  void initState() {
    super.initState();
    _bookIdCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<YuqueViewModel>();
      _syncFromVm(vm);
      vm.addListener(() => _syncFromVm(vm));
    });
  }

  void _syncFromVm(YuqueViewModel vm) {
    if (!mounted) return;
    if (_bookIdCtrl.text.isEmpty && vm.docBookId.isNotEmpty) {
      _bookIdCtrl.text = vm.docBookId;
    }
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
            _DocActionBar(vm: vm, bookIdCtrl: _bookIdCtrl),
            Expanded(child: _DocTableBody(vm: vm)),
          ],
        );
      },
    );
  }
}

// ── 操作栏 ────────────────────────────────────────────────────────────────────

class _DocActionBar extends StatelessWidget {
  final YuqueViewModel vm;
  final TextEditingController bookIdCtrl;
  const _DocActionBar({required this.vm, required this.bookIdCtrl});

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.article_outlined,
              size: 18.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            vm.docs.isEmpty ? '文档列表' : '共 ${vm.docs.length} 篇',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 180.w,
            child: TextField(
              controller: bookIdCtrl,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '输入知识库 ID',
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
          FilledButton.icon(
            onPressed: vm.isDocsLoading
                ? null
                : () => vm.fetchDocs(bookIdCtrl.text),
            icon: vm.isDocsLoading
                ? SizedBox(
                    width: 14.r,
                    height: 14.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.cloud_download_outlined, size: 16.sp),
            label: Text(
              vm.isDocsLoading ? '获取中...' : '获取文档列表',
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

// ── 表格区域 ──────────────────────────────────────────────────────────────────

class _DocTableBody extends StatelessWidget {
  final YuqueViewModel vm;
  const _DocTableBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isDocsLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              '正在获取文档列表...',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (vm.docsErrorMessage != null) {
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
                    AppColors.error.withValues(alpha: 0.15),
                    AppColors.error.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 36.sp,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              vm.docsErrorMessage!,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }
    if (vm.docs.isEmpty) {
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
                Icons.article_outlined,
                size: 36.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '输入知识库 ID 后点击「获取文档列表」',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
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
          children: [
            _DocTableHeader(),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: vm.docs.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withValues(alpha: 0.04),
                ),
                itemBuilder: (context, index) =>
                    _DocTableRow(doc: vm.docs[index], index: index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 表头 ──────────────────────────────────────────────────────────────────────

class _DocTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.contentBg,
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '标题',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 100.w,
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
              '路径 (slug)',
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

class _DocTableRow extends StatefulWidget {
  final YuqueDoc doc;
  final int index;
  const _DocTableRow({required this.doc, required this.index});

  @override
  State<_DocTableRow> createState() => _DocTableRowState();
}

class _DocTableRowState extends State<_DocTableRow> {
  bool _hovered = false;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制：$text', style: TextStyle(fontSize: 13.sp)),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        width: 300.w,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
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
    final bg = _hovered
        ? AppColors.primary.withValues(alpha: 0.04)
        : widget.index.isEven
        ? AppColors.cardBg
        : AppColors.contentBg.withValues(alpha: 0.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: bg,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _copyable(
                context,
                widget.doc.title,
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 14.sp,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        widget.doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
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
                '${widget.doc.id}',
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${widget.doc.id}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _copyable(
                context,
                widget.doc.slug,
                Text(
                  widget.doc.slug,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
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
