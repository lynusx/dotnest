import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // sidebar
  static const Color sidebarBg = Color(0xFFF2F2F7);
  static const Color sidebarItemSelected = Color(0xFFE8EAF6);
  static const Color sidebarItemHover = Color(0xFFECECF3);
  static const Color sidebarIndicator = Color(0xFF5B6EF5);

  // content
  static const Color contentBg = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);

  // text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF8B8FA8);
  // sidebar text（浅色背景下使用深色文字）
  static const Color textOnDark = Color(0xFF1A1A2E);
  static const Color textOnDarkMuted = Color(0xFF8B8FA8);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sidebarIndicator,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.contentBg,
    fontFamily: defaultTargetPlatform == TargetPlatform.macOS
        ? '.AppleSystemUIFont'
        : 'Segoe UI',
  );
}
