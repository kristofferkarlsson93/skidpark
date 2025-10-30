import 'package:flutter/material.dart';
import 'package:skidpark/database/repository/glide_test_repository.dart';
import 'package:skidpark/navigation/bottom_navigation.dart';
import 'package:skidpark/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'database/database.dart';
import 'database/repository/ski_repository.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        ProxyProvider<AppDatabase, SkiRepository>(
          update: (_, db, __) => SkiRepository(db),
        ),
        ProxyProvider<AppDatabase, GlideTestRepository>(
          update: (_, db, __) => GlideTestRepository(db),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Min skidpark',
      home: BottomNavigator(),
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
    );
  }
}
