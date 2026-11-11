// Explicit visual review, fictional account only; native biometrics are mocked.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/security/biometric_service.dart';
import 'package:sparkleen_mobile/core/settings/server_settings.dart';
import 'package:sparkleen_mobile/core/settings/server_page.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/auth/presentation/session_page.dart';
import 'package:sparkleen_mobile/features/profil/presentation/security_page.dart';

import '../test/support/auth_fakes.dart';
import '../test/features/session_security_test.dart' show FakeBiometrics;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final family in manifest.cast<Map<String, dynamic>>()) {
      final loader = FontLoader(family['family'] as String);
      for (final font in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });
  for (final dark in [false, true]) {
    for (final scenario in [
      (name: 'keamanan', page: const SecurityPage()),
      (name: 'pemulihan-sesi', page: const SessionPage()),
      (name: 'server-laptop', page: const ServerPage()),
    ]) {
      testWidgets('capture ${scenario.name} ${dark ? 'gelap' : 'terang'}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(780, 1688);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final storage = FakeTokenStorage('fixture-session');
        if (scenario.name == 'keamanan') {
          storage.biometricBinding = jsonEncode({
            'token': 'fixture-session',
            'payments': true,
          });
        }
        final repository = FakeAuthRepository();
        if (scenario.name == 'pemulihan-sesi') {
          repository.meError = const ApiException(
            code: 'NETWORK_ERROR',
            message: 'Offline',
          );
        }
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: [
              tokenStorageProvider.overrideWithValue(storage),
              authRepositoryProvider.overrideWithValue(repository),
              biometricServiceProvider.overrideWithValue(
                FakeBiometrics(storage),
              ),
              initialServerAddressProvider.overrideWithValue(
                'http://192.168.1.10:8080',
              ),
            ],
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
                home: scenario.page,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate()) {
            await precacheImage((element.widget as Image).image, element);
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'docs/screenshots/v0.0.1/${scenario.name}-${dark ? 'gelap' : 'terang'}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
