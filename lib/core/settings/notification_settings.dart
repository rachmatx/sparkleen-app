import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.showBadge = true,
    this.autoRefresh = true,
  });
  final bool showBadge, autoRefresh;
}

class NotificationSettings {
  const NotificationSettings();
  static const _key = 'sparkleen_notification_preferences';

  Future<NotificationPreferences> load() async {
    try {
      final raw = await const FlutterSecureStorage().read(key: _key);
      if (raw == null) return const NotificationPreferences();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPreferences(
        showBadge: json['show_badge'] != false,
        autoRefresh: json['auto_refresh'] != false,
      );
    } on Object {
      return const NotificationPreferences();
    }
  }

  Future<void> save(NotificationPreferences value) =>
      const FlutterSecureStorage().write(
        key: _key,
        value: jsonEncode({
          'show_badge': value.showBadge,
          'auto_refresh': value.autoRefresh,
        }),
      );
}

final notificationSettingsProvider = Provider(
  (ref) => const NotificationSettings(),
);
final initialNotificationPreferencesProvider = Provider(
  (ref) => const NotificationPreferences(),
);
final notificationPreferencesProvider =
    NotifierProvider<
      NotificationPreferencesController,
      NotificationPreferences
    >(NotificationPreferencesController.new);

class NotificationPreferencesController
    extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() =>
      ref.watch(initialNotificationPreferencesProvider);

  Future<void> change({bool? showBadge, bool? autoRefresh}) async {
    final next = NotificationPreferences(
      showBadge: showBadge ?? state.showBadge,
      autoRefresh: autoRefresh ?? state.autoRefresh,
    );
    await ref.read(notificationSettingsProvider).save(next);
    if (ref.mounted) state = next;
  }
}
