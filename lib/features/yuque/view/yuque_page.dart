import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodel/yuque_viewmodel.dart';
import 'repo_list_page.dart';

class YuquePage extends StatefulWidget {
  const YuquePage({super.key});

  @override
  State<YuquePage> createState() => _YuquePageState();
}

class _YuquePageState extends State<YuquePage> {
  late final TextEditingController _tokenCtrl;
  late final TextEditingController _loginCtrl;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController();
    _loginCtrl = TextEditingController();
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
    return Container(
      color: AppColors.contentBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildConfigCard(),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withValues(alpha: 0.06),
          ),
          const Expanded(child: RepoListPage()),
        ],
      ),
    );
  }

  // ── 共享配置卡片 ────────────────────────────────────────────────────────────

  Widget _buildConfigCard() {
    return Consumer<YuqueViewModel>(
      builder: (context, vm, _) {
        return Padding(
          padding: EdgeInsets.all(20.r),
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
                Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 16.sp,
                      color: AppColors.sidebarIndicator,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '语雀配置',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
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
                            size: 16.sp,
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
                    SizedBox(width: 16.w),
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
                          color:
                              AppColors.sidebarIndicator.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        '保存配置',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
        hintStyle:
            TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        labelStyle:
            TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide:
              BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide:
              BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide:
              BorderSide(color: AppColors.sidebarIndicator, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.contentBg,
      ),
    );
  }
}
