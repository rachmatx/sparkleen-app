import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/home/presentation/home_page.dart';

import '../support/auth_fakes.dart';
import '../support/home_fakes.dart';

class _AuthenticatedAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthAuthenticated(testPelanggan);
}

Widget _buildPage(FakeHomeRepository repository) {
  return ProviderScope(
    retry: (retryCount, error) => null,
    overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
    ],
    child: MaterialApp(theme: buildAppTheme(), home: const HomePage()),
  );
}

Future<void> _settleData(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('beranda menampilkan empty state saat data kosong', (
    tester,
  ) async {
    await tester.pumpWidget(_buildPage(FakeHomeRepository()));
    await _settleData(tester);

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Belum ada pesanan aktif.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Belum ada layanan tersedia.'),
      200,
    );
    expect(find.text('Belum ada layanan tersedia.'), findsOneWidget);
  });

  testWidgets('beranda menampilkan pesanan aktif dan katalog layanan', (
    tester,
  ) async {
    final repository = FakeHomeRepository()
      ..layananResult = testLayanan
      ..pesananAktifResult = testTransaksiAktif;

    await tester.pumpWidget(_buildPage(repository));
    await _settleData(tester);

    expect(find.text('LAU/20261021/0001'), findsOneWidget);
    expect(find.text('Dicuci'), findsOneWidget);
    expect(find.text('15 poin'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cuci Kering'), 200);
    expect(find.text('Cuci Kering'), findsOneWidget);
    expect(find.textContaining('7.000'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('4 transaksi'), 200);
    expect(find.text('4 transaksi'), findsOneWidget);
    expect(find.text('Rp 4'), findsNothing);
  });

  testWidgets('beranda menampilkan error dan tombol coba lagi', (tester) async {
    final repository = FakeHomeRepository()
      ..layananError = const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Gagal memuat layanan.',
      );

    await tester.pumpWidget(_buildPage(repository));
    await _settleData(tester);

    await tester.scrollUntilVisible(find.text('Gagal memuat layanan.'), 200);
    expect(find.text('Gagal memuat layanan.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
