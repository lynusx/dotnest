import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 主色调 - 现代化紫蓝色系
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryContainer = Color(0xFFEEF2FF);

  // 侧边栏 - 深色主题
  static const Color sidebarBg = Color(0xFF1E1E2E);
  static const Color sidebarItemSelected = Color(0xFF2D2D3F);
  static const Color sidebarItemHover = Color(0xFF252535);
  static const Color sidebarIndicator = Color(0xFF818CF8);

  // 内容区域 - 浅色渐变背景
  static const Color contentBg = Color(0xFFF8FAFC);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // 文字颜色
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // 侧边栏文字（浅色）
  static const Color textOnDark = Color(0xFFF8FAFC);
  static const Color textOnDarkMuted = Color(0xFF94A3B8);

  // 状态颜色
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDCEAFE);

  // 阴影
  static final BoxShadow shadowSm = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 4,
    offset: const Offset(0, 1),
  );

  static final BoxShadow shadowMd = BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 12,
    offset: const Offset(0, 2),
  );

  static final BoxShadow shadowLg = BoxShadow(
    color: Colors.black.withValues(alpha: 0.1),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
    ),
    scaffoldBackgroundColor: AppColors.contentBg,
    fontFamily: defaultTargetPlatform == TargetPlatform.macOS
        ? '.AppleSystemUIFont'
        : 'Segoe UI',
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      color: AppColors.cardBg,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
