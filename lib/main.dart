import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/extract/viewmodel/extract_viewmodel.dart';
import 'features/yuque/viewmodel/yuque_viewmodel.dart';
import 'layout/viewmodel/navigation_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(create: (_) => YuqueViewModel()),
        ChangeNotifierProvider(create: (_) => ExtractViewModel()),
      ],
      child: const DotNestApp(),
    ),
  );
}
