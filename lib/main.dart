import 'package:flutter/material.dart';
import 'package:skidpark/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'common/database/database.dart';
import 'common/database/repository/glide_test_repository.dart';
import 'common/database/repository/ski_repository.dart';
import 'common/database/repository/test_run_repository.dart';
import 'common/navigation/bottom_navigation.dart';
import 'common/services/volume_press_handler.dart';
import 'features/glide_testing/example_data/example_data_installer.dart';
import 'features/glide_testing/import/glide_test_import_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        ProxyProvider<AppDatabase, SkiRepository>(
          update: (_, db, _) => SkiRepository(db),
        ),
        ProxyProvider<AppDatabase, GlideTestRepository>(
          update: (_, db, _) => GlideTestRepository(db),
        ),
        ProxyProvider<AppDatabase, TestRunRepository>(
          update: (_, db, _) => TestRunRepository(db),
        ),
        ProxyProvider<AppDatabase, GlideTestImportService>(
          update: (_, db, _) => GlideTestImportService(db),
        ),
        ProxyProvider2<
          AppDatabase,
          GlideTestImportService,
          ExampleDataInstaller
        >(
          update: (_, db, importService, _) =>
              ExampleDataInstaller(db, importService),
        ),
        Provider<VolumeButtonInput>(
          create: (_) => VolumePressHandler(),
          dispose: (_, input) => input.dispose(),
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
      title: 'SkidPark',
      home: const BottomNavigator(),
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
    );
  }
}
