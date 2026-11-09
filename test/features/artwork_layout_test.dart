import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_assets.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/core/widgets/app_artwork.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/auth/presentation/login_page.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/home/presentation/home_page.dart';

import '../support/auth_fakes.dart';
import '../support/home_fakes.dart';

class _SignedIn extends AuthController {
  @override
  Future<AuthState> build() async => const AuthAuthenticated(testPelanggan);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  for (final brightness in Brightness.values) {
    testWidgets('home artwork fits a narrow ${brightness.name} viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final home = FakeHomeRepository()
        ..layananResult = testLayanan
        ..pesananAktifResult = testTransaksiAktif;
      await tester.pumpWidget(
        ProviderScope(
          retry: (retryCount, error) => null,
          overrides: [
            homeRepositoryProvider.overrideWithValue(home),
            authControllerProvider.overrideWith(_SignedIn.new),
          ],
          child: MaterialApp(
            theme: buildAppTheme(brightness: brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const HomePage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Cuci Kering'), 200);
      expect(find.text('Cuci Kering'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('login hides decorative artwork when the keyboard opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const LoginPage()),
      ),
    );
    await tester.pump();
    final loginArtwork = find.byWidgetPredicate(
      (widget) =>
          widget is IllustrationPanel && widget.asset == AppAssets.login,
    );
    expect(loginArtwork, findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();
    expect(loginArtwork, findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
