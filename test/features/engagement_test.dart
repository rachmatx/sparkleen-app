import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/loyalitas/application/loyalty_controller.dart';
import 'package:sparkleen_mobile/features/loyalitas/presentation/loyalty_page.dart';
import 'package:sparkleen_mobile/features/loyalitas/presentation/redemption_page.dart';
import 'package:sparkleen_mobile/features/notifikasi/application/notification_controller.dart';
import 'package:sparkleen_mobile/features/notifikasi/data/notification_repository.dart';
import 'package:sparkleen_mobile/features/notifikasi/presentation/notification_page.dart';

import '../support/auth_fakes.dart';
import '../support/engagement_fakes.dart';

Widget app(
  Widget page, {
  FakeNotifications? notifications,
  FakeLoyalty? loyalty,
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    notificationRepositoryProvider.overrideWithValue(
      notifications ?? FakeNotifications(),
    ),
    loyaltyRepositoryProvider.overrideWithValue(loyalty ?? FakeLoyalty()),
    tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
  ],
  child: MaterialApp(
    theme: buildAppTheme(brightness: brightness),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: page,
  ),
);
ProviderContainer container(
  FakeLoyalty loyalty, {
  FakeNotifications? notifications,
}) => ProviderContainer(
  retry: (_, _) => null,
  overrides: [
    loyaltyRepositoryProvider.overrideWithValue(loyalty),
    notificationRepositoryProvider.overrideWithValue(
      notifications ?? FakeNotifications(),
    ),
    tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
  ],
);
void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  testWidgets('inbox empty and unread states remain explicit', (tester) async {
    await tester.pumpWidget(
      app(
        const NotificationPage(),
        notifications: FakeNotifications()
          ..current = const NotificationList(items: []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
  });
  testWidgets('notification opens typed order after marking it read', (
    tester,
  ) async {
    final repository = FakeNotifications();
    final router = GoRouter(
      initialLocation: '/notifikasi',
      routes: [
        GoRoute(
          path: '/notifikasi',
          builder: (_, _) => const NotificationPage(),
        ),
        GoRoute(
          path: '/pesanan/1',
          builder: (_, _) => const Scaffold(body: Text('Detail tujuan')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cucian siap diambil'));
    await tester.pumpAndSettle();
    expect(repository.reads, 1);
    expect(find.text('Detail tujuan'), findsOneWidget);
  });
  testWidgets('read-all failure keeps unread cards and explains error', (
    tester,
  ) async {
    final repository = FakeNotifications();
    await tester.pumpWidget(
      app(const NotificationPage(), notifications: repository),
    );
    await tester.pumpAndSettle();
    repository.error = const ApiException(
      code: 'NETWORK_ERROR',
      message: 'Koneksi terputus',
    );
    await tester.tap(find.text('Tandai semua dibaca'));
    await tester.pumpAndSettle();
    expect(find.text('Belum dibaca'), findsOneWidget);
    expect(find.text('Koneksi terputus'), findsOneWidget);
  });
  testWidgets('badge refreshes only in foreground', (tester) async {
    final repository = FakeNotifications();
    await tester.pumpWidget(
      app(const Scaffold(body: NotificationBell()), notifications: repository),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notifikasi, 1 belum dibaca'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(repository.summaryCalls, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 60));
    expect(repository.summaryCalls, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repository.summaryCalls, 3);
  });
  test(
    'pagination deduplicates and read-all preserves initial newest cutoff',
    () async {
      final repository = FakeNotifications()
        ..current = NotificationList(
          items: [testNotification(100)],
          unread: 1,
          latestId: 100,
          lastPage: 2,
        )
        ..next = NotificationList(
          items: [testNotification(100), testNotification(90)],
          unread: 2,
          latestId: 90,
          page: 2,
          lastPage: 2,
        );
      final c = container(FakeLoyalty(), notifications: repository);
      final sub = c.listen(notificationsProvider, (_, _) {});
      addTearDown(() {
        sub.close();
        c.dispose();
      });
      await c.read(notificationsProvider.future);
      await c.read(notificationsProvider.notifier).loadMore();
      expect(c.read(notificationsProvider).value!.result.items.length, 2);
      await c.read(notificationsProvider.notifier).mark();
      expect(repository.cutoff, 100);
    },
  );
  test('late read completion cannot replace the next account inbox', () async {
    final repository = FakeNotifications()..delayedRead = Completer();
    final c = container(FakeLoyalty(), notifications: repository);
    final sub = c.listen(notificationsProvider, (_, _) {});
    addTearDown(() {
      sub.close();
      c.dispose();
    });
    await c.read(notificationsProvider.future);
    final old = c.read(notificationsProvider.notifier).mark(id: 100);
    repository.current = const NotificationList(items: []);
    c.read(customerSessionRevisionProvider.notifier).advance();
    await c.read(notificationsProvider.future);
    repository.delayedRead!.complete();
    expect(await old, false);
    expect(c.read(notificationsProvider).value!.result.items, isEmpty);
  });
  testWidgets('loyalty shows server balance and history start boundary', (
    tester,
  ) async {
    await tester.pumpWidget(app(const LoyaltyPage()));
    await tester.pumpAndSettle();
    expect(find.text('100 poin'), findsOneWidget);
    expect(
      find.textContaining('sejak fitur riwayat diaktifkan'),
      findsOneWidget,
    );
  });
  testWidgets('blocked order offers reason and no submit', (tester) async {
    await tester.pumpWidget(
      app(
        const RedemptionPage(id: 1),
        loyalty: FakeLoyalty()..current = testQuote(blocked: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tinjau penukaran'), findsNothing);
    expect(find.textContaining('Batalkan tagihan online'), findsOneWidget);
  });
  testWidgets('redemption shows adjustment, confirms, and submits once', (
    tester,
  ) async {
    final repository = FakeLoyalty()..delayed = Completer();
    await tester.pumpWidget(
      app(const RedemptionPage(id: 1), loyalty: repository),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '20');
    await tester.pumpAndSettle();
    expect(find.textContaining('disesuaikan turun 1 poin'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tinjau penukaran'));
    await tester.pumpAndSettle();
    expect(repository.redemptions, 0);
    expect(
      find.textContaining('Saldo setelah penukaran: 79 poin'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ya, tukar poin'));
    await tester.pump();
    expect(repository.redemptions, 1);
    expect(repository.submittedPoints, 20);
    expect(repository.submittedTotal, 35000);
    repository.delayed!.complete(testQuote(redeemed: true));
    await tester.pumpAndSettle();
    expect(find.text('Poin berhasil ditukar'), findsOneWidget);
    expect(find.text('Tinjau penukaran'), findsNothing);
  });
  test(
    'network retry preserves request identity and single busy submission',
    () async {
      final repository = FakeLoyalty()
        ..error = const ApiException(code: 'NETWORK_ERROR', message: 'Retry');
      final c = container(repository);
      final sub = c.listen(redemptionProvider(1), (_, _) {});
      addTearDown(() {
        sub.close();
        c.dispose();
      });
      await c.read(redemptionProvider(1).future);
      await c.read(redemptionProvider(1).notifier).redeem(20);
      expect(c.read(redemptionProvider(1)).value!.error, isNotNull);
      repository.error = null;
      repository.delayed = Completer();
      final pending = c.read(redemptionProvider(1).notifier).redeem(20);
      await c.read(redemptionProvider(1).notifier).redeem(20);
      expect(repository.redemptions, 2);
      expect(repository.keys[0], repository.keys[1]);
      repository.delayed!.complete(testQuote(redeemed: true));
      await pending;
    },
  );
  test(
    'late redemption cannot update a new account or refresh its profile',
    () async {
      final repository = FakeLoyalty()..delayed = Completer();
      final c = container(repository);
      final sub = c.listen(redemptionProvider(1), (_, _) {});
      addTearDown(() {
        sub.close();
        c.dispose();
      });
      await c.read(redemptionProvider(1).future);
      final old = c.read(redemptionProvider(1).notifier).redeem(20);
      repository.current = testQuote(blocked: true);
      c.read(customerSessionRevisionProvider.notifier).advance();
      await c.read(redemptionProvider(1).future);
      repository.delayed!.complete(testQuote(redeemed: true));
      await old;
      expect(c.read(redemptionProvider(1)).value!.quote.canRedeem, false);
      expect(c.read(redemptionProvider(1)).value!.quote.redemption, isNull);
    },
  );
  for (final brightness in Brightness.values) {
    for (final page in [
      const NotificationPage(),
      const LoyaltyPage(),
      const RedemptionPage(id: 1),
    ]) {
      testWidgets('${page.runtimeType} fits 320px / text 1.8 / $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(page, brightness: brightness, scale: 1.8));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
