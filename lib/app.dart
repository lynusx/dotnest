import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'layout/main_layout.dart';

class DotNestApp extends StatelessWidget {
  const DotNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1280, 800),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        title: 'DotNest',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: child,
      ),
      child: const MainLayout(),
    );
  }
}
