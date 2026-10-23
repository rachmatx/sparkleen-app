import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/auth/presentation/login_page.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/home/presentation/home_page.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';
import 'package:sparkleen_mobile/features/pesanan/presentation/pesanan_page.dart';
import 'package:sparkleen_mobile/features/profil/presentation/profil_page.dart';
import 'package:sparkleen_mobile/main.dart';

import 'support/auth_fakes.dart';
import 'support/home_fakes.dart';
import 'support/pesanan_fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Widget buildApp({
    required FakeTokenStorage storage,
    FakeAuthRepository? auth,
    FakeHomeRepository? home,
    FakeTransaksiRepository? pesanan,
  }) {
    final homeRepository = (home ?? FakeHomeRepository())
      ..layananResult = testLayanan
      ..pesananAktifResult = testTransaksiAktif;

    return ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
        homeRepositoryProvider.overrideWithValue(homeRepository),
        transaksiRepositoryProvider.overrideWithValue(
          pesanan ??
              FakeTransaksiRepository(
                results: {
                  'aktif:1': [testTransaksi(87)],
                },
              ),
        ),
      ],
      child: const SparkleenApp(),
    );
  }

  testWidgets('tanpa token aplikasi membuka halaman masuk', (tester) async {
    await tester.pumpWidget(buildApp(storage: FakeTokenStorage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('dengan token aplikasi membuka beranda dan tiga tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(storage: FakeTokenStorage('token-aktif')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Pesanan'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PesananPage), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ProfilPage), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });
}
