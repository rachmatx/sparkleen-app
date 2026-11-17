import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/settings/notification_settings.dart';
import 'package:sparkleen_mobile/features/notifikasi/application/notification_controller.dart';
import 'package:sparkleen_mobile/features/notifikasi/presentation/notification_page.dart';

import '../support/engagement_fakes.dart';

class _Settings extends NotificationSettings {
  NotificationPreferences? saved;
  bool fail = false;
  @override
  Future<void> save(NotificationPreferences value) async {
    if (fail) throw StateError('storage unavailable');
    saved = value;
  }
}

void main() {
  test('failed persistence does not change active preferences', () async {
    final settings = _Settings()..fail = true;
    final c = ProviderContainer.test(
      overrides: [notificationSettingsProvider.overrideWithValue(settings)],
    );
    addTearDown(c.dispose);
    expect(c.read(notificationPreferencesProvider).showBadge, isTrue);
    await expectLater(
      c.read(notificationPreferencesProvider.notifier).change(showBadge: false),
      throwsStateError,
    );
    expect(c.read(notificationPreferencesProvider).showBadge, isTrue);
  });
  testWidgets('preferences control actual badge and automatic polling', (
    tester,
  ) async {
    final settings = _Settings();
    final notifications = FakeNotifications();
    final c = ProviderContainer.test(
      overrides: [
        notificationSettingsProvider.overrideWithValue(settings),
        notificationRepositoryProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: NotificationBell())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
    final first = notifications.summaryCalls;
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(notifications.summaryCalls, greaterThan(first));
    await c
        .read(notificationPreferencesProvider.notifier)
        .change(showBadge: false, autoRefresh: false);
    await tester.pumpAndSettle();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    final paused = notifications.summaryCalls;
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(notifications.summaryCalls, paused);
    expect(settings.saved!.autoRefresh, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
