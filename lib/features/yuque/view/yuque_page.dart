import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../model/yuque_repo.dart';
import '../viewmodel/yuque_viewmodel.dart';

class YuquePage extends StatefulWidget {
  const YuquePage({super.key});

  @override
  State<YuquePage> createState() => _YuquePageState();
}

class _YuquePageState extends State<YuquePage> {
  late final TextEditingController _tokenCtrl;
  late final TextEditingController _loginCtrl;
  bool _obscureToken = false;

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController();
    _loginCtrl = TextEditingController();
    // 首帧之后读取持久化数据，并监听后续变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<YuqueViewModel>();
      _syncFromVm(vm);
      vm.addListener(() => _syncFromVm(vm));
    });
  }

  void _syncFromVm(YuqueViewModel vm) {
    if (!mounted) return;
    if (_tokenCtrl.text.isEmpty && vm.token.isNotEmpty) {
      _tokenCtrl.text = vm.token;
    }
    if (_loginCtrl.text.isEmpty && vm.login.isNotEmpty) {
      _loginCtrl.text = vm.login;
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _loginCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<YuqueViewModel>(
      builder: (context, vm, _) {
        return Container(
          color: AppColors.contentBg,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildConfigCard(vm)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                sliver: _buildRepoContent(vm),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 配置卡片 ────────────────────────────────────────────────────────────────

  Widget _buildConfigCard(YuqueViewModel vm) {
    return Padding(
      padding: EdgeInsets.all(24.r),
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
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 18.sp,
                  color: AppColors.sidebarIndicator,
                ),
                SizedBox(width: 8.w),
                Text(
                  '语雀配置',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // 输入字段行
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _tokenCtrl,
                    label: 'API Token',
                    hint: '请输入语雀 API Token',
                    obscure: _obscureToken,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18.sp,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureToken = !_obscureToken),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                SizedBox(
                  width: 220.w,
                  child: _buildTextField(
                    controller: _loginCtrl,
                    label: '用户名（login）',
                    hint: '语雀登录名',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // 操作按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () => vm.saveConfig(
                            _tokenCtrl.text,
                            _loginCtrl.text,
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.sidebarIndicator,
                    side: BorderSide(
                      color: AppColors.sidebarIndicator.withValues(alpha: 0.5),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text('保存配置', style: TextStyle(fontSize: 13.sp)),
                ),
                SizedBox(width: 12.w),
                FilledButton.icon(
                  onPressed: vm.isLoading
                      ? null
                      : () => vm.fetchRepos(
                            _tokenCtrl.text,
                            _loginCtrl.text,
                          ),
                  icon: vm.isLoading
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
                    vm.isLoading ? '获取中...' : '获取知识库列表',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sidebarIndicator,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        labelStyle: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
    );
  }

  // ── 知识库内容区域 ──────────────────────────────────────────────────────────

  Widget _buildRepoContent(YuqueViewModel vm) {
    if (vm.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40.sp,
                color: Colors.redAccent.withValues(alpha: 0.7),
              ),
              SizedBox(height: 12.h),
              Text(
                vm.errorMessage!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.repos.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 48.sp,
                color: AppColors.sidebarIndicator.withValues(alpha: 0.4),
              ),
              SizedBox(height: 16.h),
              Text(
                '填写 Token 和用户名后点击「获取知识库列表」',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              '共 ${vm.repos.length} 个知识库',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320.w,
            mainAxisExtent: 110.h,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: vm.repos.length,
          itemBuilder: (context, index) => _RepoCard(repo: vm.repos[index]),
        ),
      ],
    );
  }
}

// ── 知识库卡片 ────────────────────────────────────────────────────────────────

class _RepoCard extends StatelessWidget {
  final YuqueRepo repo;

  const _RepoCard({required this.repo});

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
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.book_outlined,
                size: 14.sp,
                color: AppColors.sidebarIndicator,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  repo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.sidebarIndicator.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '${repo.itemsCount} 篇',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.sidebarIndicator,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: Text(
              (repo.description).isEmpty
                  ? '暂无简介'
                  : repo.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            repo.slug,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
