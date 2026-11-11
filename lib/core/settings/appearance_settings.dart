import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppearanceSettings {
  const AppearanceSettings();
  static const _key = 'sparkleen_theme_mode';
  Future<ThemeMode> load() async {
    try {
      final name = await const FlutterSecureStorage().read(key: _key);
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == name,
        orElse: () => ThemeMode.system,
      );
    } on Object {
      return ThemeMode.system;
    }
  }

  Future<void> save(ThemeMode mode) =>
      const FlutterSecureStorage().write(key: _key, value: mode.name);
}

final appearanceSettingsProvider = Provider(
  (ref) => const AppearanceSettings(),
);
final initialThemeModeProvider = Provider((ref) => ThemeMode.system);
final themeModeProvider = NotifierProvider<AppearanceController, ThemeMode>(
  AppearanceController.new,
);

class AppearanceController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);
  Future<void> change(ThemeMode mode) async {
    await ref.read(appearanceSettingsProvider).save(mode);
    if (ref.mounted) state = mode;
  }
}

String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Ikuti sistem',
  ThemeMode.light => 'Terang',
  ThemeMode.dark => 'Gelap',
};
