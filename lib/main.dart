import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'layout/viewmodel/navigation_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => NavigationViewModel())],
      child: const DotNestApp(),
    ),
  );
}
