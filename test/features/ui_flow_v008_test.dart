import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/main.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/features/auth/presentation/session_page.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/router/app_router.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/jemput/application/pickup_controller.dart';
import 'package:sparkleen_mobile/features/jemput/presentation/pickup_form_page.dart';
import 'package:sparkleen_mobile/features/jemput/presentation/pickup_page.dart';
import 'package:sparkleen_mobile/features/notifikasi/application/notification_controller.dart';
import 'package:sparkleen_mobile/features/notifikasi/presentation/notification_page.dart';
import 'package:sparkleen_mobile/features/pengaturan/presentation/notification_settings_page.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_detail.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_repository.dart';
import 'package:sparkleen_mobile/features/alamat/application/address_controller.dart';

import '../support/auth_fakes.dart';
import '../support/home_fakes.dart';
import '../support/engagement_fakes.dart';
import '../support/address_fakes.dart';
import '../support/redesign_fixtures.dart';
import 'pickup_test.dart' show FakePickupRepository, pickup;

class _CancelledUnlock extends AuthController {
  int attempts = 0;
  @override
  Future<AuthState> build() async => const AuthLocked();
  @override
  Future<void> unlock() async {
    attempts++;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  testWidgets(
    'biometric unlock prompts once; cancellation permits explicit retry',
    (tester) async {
      final controller = _CancelledUnlock();
      final c = ProviderContainer.test(
        overrides: [authControllerProvider.overrideWith(() => controller)],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(theme: buildAppTheme(), home: const SessionPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.attempts, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.attempts, 1);
      await tester.ensureVisible(find.text('Buka dengan biometrik'));
      await tester.tap(find.text('Buka dengan biometrik'));
      await tester.pumpAndSettle();
      expect(controller.attempts, 2);
    },
  );
  ProviderContainer setup(
    FakePickupRepository pickups, {
    TransaksiRepository? orders,
  }) => ProviderContainer.test(
    overrides: [
      startupReadyProvider.overrideWith((ref) async {}),
      tokenStorageProvider.overrideWithValue(FakeTokenStorage('demo')),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      homeRepositoryProvider.overrideWithValue(
        FakeHomeRepository()
          ..layananResult = testLayanan
          ..pesananAktifResult = testTransaksiAktif,
      ),
      transaksiRepositoryProvider.overrideWithValue(
        orders ?? redesignTransaksiRepository(),
      ),
      pickupRepositoryProvider.overrideWithValue(pickups),
      notificationRepositoryProvider.overrideWithValue(FakeNotifications()),
      addressRepositoryProvider.overrideWithValue(FakeAddresses()),
    ],
  );
  Future<void> launch(WidgetTester tester, ProviderContainer c) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const SparkleenApp()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'home prioritizes active order; pickup labels match their actual destination',
    (tester) async {
      final pickups = FakePickupRepository();
      final c = setup(pickups);
      addTearDown(c.dispose);
      await launch(tester, c);
      final shortcut = find.byKey(const ValueKey('home-pickup-shortcut'));
      expect(
        tester.getTopLeft(find.text('Pesanan aktif')).dy,
        lessThan(tester.getTopLeft(shortcut).dy),
      );
      await tester.ensureVisible(find.text('Jadwalkan jemput'));
      await tester.tap(find.text('Jadwalkan jemput'));
      await tester.pumpAndSettle();
      expect(find.byType(PickupFormPage), findsOneWidget);
      c.read(routerProvider).pop();
      pickups.items = [pickup()];
      c.invalidate(pickupControllerProvider);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lihat penjemputan'));
      await tester.tap(find.text('Lihat penjemputan'));
      await tester.pumpAndSettle();
      expect(find.byType(PickupPage), findsOneWidget);
      expect(pickups.creates, 0);
    },
  );
  testWidgets('settings notification opens preferences rather than inbox', (
    tester,
  ) async {
    final c = setup(FakePickupRepository());
    addTearDown(c.dispose);
    await launch(tester, c);
    c.read(routerProvider).push('/pengaturan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationSettingsPage), findsOneWidget);
    expect(find.byType(NotificationPage), findsNothing);
    expect(find.byType(SwitchListTile), findsNWidgets(2));
  });
  testWidgets(
    'unpaid order exposes payment action without scrolling the timeline',
    (tester) async {
      final orders = redesignTransaksiRepository();
      final d = orders.detailResults[87]!;
      orders.detailResults[87] = TransaksiDetail(
        id: d.id,
        noNota: d.noNota,
        tglMasuk: d.tglMasuk,
        tglEstimasi: d.tglEstimasi,
        totalBerat: d.totalBerat,
        totalBiaya: d.totalBiaya,
        diskon: d.diskon,
        grandTotal: d.grandTotal,
        status: d.status,
        statusLabel: d.statusLabel,
        statusPembayaran: 'belum_lunas',
        items: d.items,
        pembayaran: d.pembayaran,
        timeline: d.timeline,
      );
      final c = setup(FakePickupRepository(), orders: orders);
      addTearDown(c.dispose);
      await launch(tester, c);
      c.read(routerProvider).push('/pesanan/87');
      await tester.pumpAndSettle();
      final pay = find.byKey(const ValueKey('order-pay-now'));
      expect(pay.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(pay).dy, lessThan(844));
      expect(find.text('Disetrika'), findsNothing);
    },
  );
}
