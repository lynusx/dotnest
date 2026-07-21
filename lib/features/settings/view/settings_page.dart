import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../yuque/viewmodel/yuque_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            _buildYuqueConfigCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildYuqueConfigCard() {
    return Consumer<YuqueViewModel>(
      builder: (context, vm, _) {
        return Container(
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
                    Icons.cloud_sync_rounded,
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
                        : () =>
                              vm.saveConfig(_tokenCtrl.text, _loginCtrl.text),
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
                ],
              ),
            ],
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
        hintStyle: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        labelStyle: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.sidebarIndicator, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.contentBg,
      ),
    );
  }
}
