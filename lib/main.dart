import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const SparkleenApp(),
    ),
  );
}

class SparkleenApp extends ConsumerWidget {
  const SparkleenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Sparkleen',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ClipRect(child: child!),
          ),
        ),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
