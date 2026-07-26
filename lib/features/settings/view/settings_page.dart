import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../yuque/viewmodel/yuque_viewmodel.dart';
import '../viewmodel/settings_viewmodel.dart';

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
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(32.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDisplaySettingsCard(),
                  SizedBox(height: 24.h),
                  _buildYuqueConfigCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              Icons.settings_rounded,
              size: 24.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '设置',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '配置应用显示和语雀 API 连接',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySettingsCard() {
    return Consumer<SettingsViewModel>(
      builder: (context, settings, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [AppColors.shadowMd],
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.text_fields_rounded,
                      size: 20.sp,
                      color: AppColors.info,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '显示设置',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '字体大小',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '调整界面文字的显示大小',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 24.w),
                  Container(
                    width: 400.w,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.contentBg,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.text_decrease_rounded,
                              size: 16.sp,
                              color: AppColors.textSecondary,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor:
                                      AppColors.cardBorder.withValues(alpha: 0.5),
                                  thumbColor: AppColors.primary,
                                  overlayColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  value: settings.fontScale,
                                  min: SettingsViewModel.minFontScale,
                                  max: SettingsViewModel.maxFontScale,
                                  onChanged: (value) => settings.setFontScale(value),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.text_increase_rounded,
                              size: 20.sp,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 12.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                '${(settings.fontScale * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '示例文字 Example Text 123',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: settings.resetFontScale,
                              icon: Icon(Icons.refresh_rounded, size: 16.sp),
                              label: Text(
                                '恢复默认',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYuqueConfigCard() {
    return Consumer<YuqueViewModel>(
      builder: (context, vm, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [AppColors.shadowMd],
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      size: 20.sp,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '语雀配置',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '配置语雀 API 访问凭证',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
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
                  Expanded(
                    child: _buildTextField(
                      controller: _loginCtrl,
                      label: '用户名（login）',
                      hint: '语雀登录名',
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Padding(
                    padding: EdgeInsets.only(top: 28.h),
                    child: FilledButton.icon(
                      onPressed: vm.isLoading
                          ? null
                          : () => vm.saveConfig(_tokenCtrl.text, _loginCtrl.text),
                      icon: vm.isLoading
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.save_rounded, size: 18.sp),
                      label: Text(
                        vm.isLoading ? '保存中...' : '保存配置',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 14.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18.sp,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        '获取 Token：登录语雀 → 个人设置 → Token 管理 → 新建 Token',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.info,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            filled: true,
            fillColor: AppColors.contentBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
