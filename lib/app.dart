import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/viewmodel/settings_viewmodel.dart';
import 'layout/main_layout.dart';

class DotNestApp extends StatelessWidget {
  const DotNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1280, 800),
      minTextAdapt: true,
      builder: (context, child) => Consumer<SettingsViewModel>(
        builder: (context, settings, _) => MaterialApp(
          title: 'DotNest',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          builder: (context, widget) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
            child: widget!,
          ),
          home: child,
        ),
      ),
      child: const MainLayout(),
    );
  }
}
