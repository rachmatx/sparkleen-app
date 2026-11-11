import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/main.dart';
import 'package:sparkleen_mobile/core/widgets/app_artwork.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/router/app_router.dart';
import 'package:sparkleen_mobile/core/settings/appearance_settings.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/loyalitas/application/loyalty_controller.dart';
import 'package:sparkleen_mobile/features/notifikasi/application/notification_controller.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';
import 'package:sparkleen_mobile/features/pesanan/presentation/pesanan_page.dart';
import 'package:sparkleen_mobile/features/pengaturan/presentation/settings_page.dart';

import '../support/auth_fakes.dart';
import '../support/home_fakes.dart';
import '../support/engagement_fakes.dart';
import '../support/pesanan_fakes.dart';
import '../support/redesign_fixtures.dart';

class MemoryAppearance extends AppearanceSettings {
  ThemeMode saved = ThemeMode.system;
  bool fail = false;
  @override
  Future<void> save(ThemeMode mode) async {
    if (fail) throw StateError('storage failed');
    saved = mode;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      for (final family in ['Manrope', 'PlusJakartaSans']) {
        final loader = FontLoader(family);
        loader.addFont(
          rootBundle.load(
            'assets/fonts/$family-${family == 'Manrope' ? 400 : 600}.ttf',
          ),
        );
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  ProviderContainer setup({
    FakeTransaksiRepository? orders,
    MemoryAppearance? appearance,
  }) => ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [
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
      loyaltyRepositoryProvider.overrideWithValue(FakeLoyalty()),
      notificationRepositoryProvider.overrideWithValue(FakeNotifications()),
      appearanceSettingsProvider.overrideWithValue(
        appearance ?? MemoryAppearance(),
      ),
    ],
  );
  Future<void> launch(
    WidgetTester tester,
    ProviderContainer c, {
    GlobalKey? capture,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: RepaintBoundary(key: capture, child: const SparkleenApp()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final assets = find
        .byType(AppArtwork)
        .evaluate()
        .map((el) => (el.widget as AppArtwork).asset)
        .toSet();
    await tester.runAsync(
      () => Future.wait(
        assets.map(
          (asset) => precacheImage(AssetImage(asset), key.currentContext!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('../.tooling/ui-qa/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('points to orders works before and after branch initialization', (
    tester,
  ) async {
    final c = setup();
    addTearDown(c.dispose);
    await launch(tester, c);
    for (var n = 0; n < 2; n++) {
      await tester.tap(find.text('15 poin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih pesanan'));
      await tester.pumpAndSettle();
      expect(find.byType(PesananPage), findsOneWidget);
      for (final label in ['Aktif', 'Selesai', 'Semua']) {
        expect(find.widgetWithText(TextButton, label), findsOneWidget);
      }
      expect(find.text(testTransaksiAktif.noNota), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Beranda'),
        ),
      );
      await tester.pumpAndSettle();
    }
  });
  testWidgets('history fetches 20 at a time only after explicit user action', (
    tester,
  ) async {
    final orders = FakeTransaksiRepository(
      lastPage: 2,
      results: {
        'aktif:1': [for (var i = 1; i <= 20; i++) testTransaksi(i)],
        'aktif:2': [for (var i = 21; i <= 40; i++) testTransaksi(i)],
      },
    );
    final c = setup(orders: orders);
    addTearDown(c.dispose);
    await launch(tester, c);
    c.read(routerProvider).go('/pesanan');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lihat semua pesanan'),
      500,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();
    expect(orders.calls, [(status: 'aktif', page: 1)]);
    expect(orders.perPageCalls, [20]);
    await tester.tap(find.text('Lihat semua pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat pesanan'), findsOneWidget);
    expect(orders.calls.length, 1);
    await tester.scrollUntilVisible(
      find.text('Muat 20 berikutnya'),
      500,
      maxScrolls: 40,
    );
    await tester.tap(find.text('Muat 20 berikutnya'));
    await tester.pumpAndSettle();
    expect(orders.calls.last, (status: 'aktif', page: 2));
    expect(orders.perPageCalls, [20, 20]);
    expect(c.read(pesananControllerProvider).value!.items.length, 40);
    expect(tester.takeException(), isNull);
    c.read(routerProvider).pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lihat semua pesanan'),
      500,
      maxScrolls: 40,
    );
    expect(find.text('Lihat semua pesanan'), findsOneWidget);
  });
  testWidgets('settings persists dark theme and profile gear opens settings', (
    tester,
  ) async {
    final memory = MemoryAppearance();
    final c = setup(appearance: memory);
    addTearDown(c.dispose);
    final key = GlobalKey();
    await launch(tester, c, capture: key);
    await capture(tester, key, 'home-light');
    c.read(routerProvider).go('/profil');
    await tester.pumpAndSettle();
    await capture(tester, key, 'profile-light');
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    await tester.tap(find.text('Tampilan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    expect(memory.saved, ThemeMode.dark);
    expect(c.read(themeModeProvider), ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
    await capture(tester, key, 'settings-dark');
    c.read(routerProvider).go('/beranda');
    await tester.pumpAndSettle();
    await capture(tester, key, 'home-dark');
    expect(tester.takeException(), isNull);
  });
  test('failed theme persistence leaves active mode unchanged', () async {
    final storage = MemoryAppearance()..fail = true;
    final c = setup(appearance: storage);
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.system);
    await expectLater(
      c.read(themeModeProvider.notifier).change(ThemeMode.dark),
      throwsStateError,
    );
    expect(c.read(themeModeProvider), ThemeMode.system);
  });
}
