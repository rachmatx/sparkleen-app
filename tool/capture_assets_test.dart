// Run explicitly with `flutter test tool/capture_assets_test.dart`.
// Screenshots use the existing fake repositories; no customer data is fetched.
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/home/data/layanan.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';
import 'package:sparkleen_mobile/main.dart';

import '../test/support/auth_fakes.dart';
import '../test/support/home_fakes.dart';
import '../test/support/pesanan_fakes.dart';

void main() {
  const output = String.fromEnvironment(
    'VISUAL_OUTPUT',
    defaultValue: 'build/visual-review',
  );
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    // This explicit capture tool loads public Google Fonts like the app does.
    // Ordinary unit/widget tests retain Flutter's default HTTP isolation.
    HttpOverrides.global = null;
    final fontCache = Directory('build/visual-review/font-cache').absolute;
    await fontCache.create(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => call.method == 'getApplicationSupportDirectory'
              ? fontCache.path
              : null,
        );
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final loader = FontLoader(entry['family'] as String);
      for (final font
          in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
    buildAppTheme();
    await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 45));
  });

  for (final scenario in [
    (name: 'beranda-aset', dark: false, login: false, empty: false),
    (name: 'beranda-aset-gelap', dark: true, login: false, empty: false),
    (name: 'login-aset', dark: false, login: true, empty: false),
    (name: 'pesanan-kosong-aset', dark: true, login: false, empty: true),
  ]) {
    testWidgets('capture ${scenario.name}', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.platformBrightnessTestValue = scenario.dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      final home = FakeHomeRepository()
        ..layananResult = [
          ...testLayanan,
          const Layanan(
            id: 2,
            nama: 'Cuci & Setrika',
            hargaPerKg: 10000,
            estimasiHari: 3,
          ),
        ]
        ..pesananAktifResult = scenario.empty ? null : testTransaksiAktif;
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          retry: (retryCount, error) => null,
          overrides: [
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage(scenario.login ? null : 'demo-token'),
            ),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            homeRepositoryProvider.overrideWithValue(home),
            transaksiRepositoryProvider.overrideWithValue(
              FakeTransaksiRepository(),
            ),
          ],
          child: RepaintBoundary(key: boundaryKey, child: const SparkleenApp()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final context = boundaryKey.currentContext!;
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      await tester.runAsync(() async {
        for (final image in images) {
          if (!context.mounted) return;
          await precacheImage(image.image, context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      if (!context.mounted) fail('Capture page was unmounted.');
      final boundary = context.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$output/${scenario.name}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
