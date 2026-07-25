import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/extract/viewmodel/extract_viewmodel.dart';
import 'features/link_rewrite/viewmodel/link_rewrite_viewmodel.dart';
import 'features/settings/viewmodel/settings_viewmodel.dart';
import 'features/yuque/viewmodel/yuque_viewmodel.dart';
import 'layout/viewmodel/navigation_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(create: (_) => YuqueViewModel()),
        ChangeNotifierProvider(create: (_) => ExtractViewModel()),
        ChangeNotifierProvider(create: (_) => LinkRewriteViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: const DotNestApp(),
    ),
  );
}
