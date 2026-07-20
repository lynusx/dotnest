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
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Row(
        children: [
          Text(
            vm.docs.isEmpty ? '文档列表' : '共 ${vm.docs.length} 篇文档',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
                : Icon(Icons.cloud_download_outlined, size: 15.sp),
            label: Text(
              vm.isDocsLoading ? '获取中...' : '获取文档列表',
              style: TextStyle(fontSize: 13.sp),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sidebarIndicator,
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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

class _DocTableBody extends StatelessWidget {
  final YuqueViewModel vm;
  const _DocTableBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isDocsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.docsErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 36.sp,
                color: Colors.redAccent.withValues(alpha: 0.7)),
            SizedBox(height: 10.h),
            Text(vm.docsErrorMessage!,
                style: TextStyle(
                    fontSize: 13.sp, color: AppColors.textPrimary)),
          ],
        ),
      );
    }
    if (vm.docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined,
                size: 44.sp,
                color: AppColors.sidebarIndicator.withValues(alpha: 0.35)),
            SizedBox(height: 14.h),
            Text('输入知识库 ID 后点击「获取文档列表」',
                style: TextStyle(
                    fontSize: 13.sp, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
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
            _DocTableHeader(),
            Divider(
                height: 1,
                thickness: 1,
                color: Colors.black.withValues(alpha: 0.06)),
            Expanded(
              child: ListView.separated(
                itemCount: vm.docs.length,
                separatorBuilder: (_, _) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withValues(alpha: 0.04)),
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
      color: AppColors.contentBg,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Widget _copyable(BuildContext context, String value, Widget child) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _copy(context, value),
        child: child,
      ),
    );
  }

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
              child: _copyable(
                context,
                widget.doc.title,
                Text(
                  widget.doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 90.w,
              child: _copyable(
                context,
                '${widget.doc.id}',
                Text(
                  '${widget.doc.id}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

