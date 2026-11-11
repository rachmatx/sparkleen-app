import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/server_settings.dart';
import 'core/settings/appearance_settings.dart';
import 'core/security/session_boundary.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Manrope',
      'Plus Jakarta Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final server = await const ServerSettings().load();
  final appearance = await const AppearanceSettings().load();
  runApp(
    ProviderScope(
      overrides: [
        initialServerAddressProvider.overrideWithValue(server),
        initialThemeModeProvider.overrideWithValue(appearance),
      ],
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
      themeMode: ref.watch(themeModeProvider),
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
            child: ClipRect(child: SessionBoundary(child: child!)),
          ),
        ),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
