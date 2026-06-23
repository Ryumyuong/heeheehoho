import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/pixel_theme.dart';
import 'features/pet/application/pet_providers.dart';
import 'features/pet/data/pet_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final petRepo = await PetRepository.open();

  runApp(
    ProviderScope(
      overrides: [
        petRepositoryProvider.overrideWithValue(petRepo),
      ],
      child: const HeeheehohoApp(),
    ),
  );
}

class HeeheehohoApp extends StatelessWidget {
  const HeeheehohoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'heeheehoho',
      debugShowCheckedModeBanner: false,
      theme: PixelTheme.light,
      routerConfig: appRouter,
    );
  }
}
