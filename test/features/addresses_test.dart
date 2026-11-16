import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/features/alamat/application/address_controller.dart';
import 'package:sparkleen_mobile/features/alamat/data/address_repository.dart';
import 'package:sparkleen_mobile/features/alamat/presentation/address_page.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';

import '../support/address_fakes.dart';
import '../support/auth_fakes.dart';

class SignedIn extends AuthController {
  @override
  Future<AuthState> build() async => const AuthAuthenticated(testPelanggan);
  @override
  Future<void> refreshMe() async {}
}

Widget app(
  FakeAddresses repository, {
  Widget page = const AddressPage(),
  Brightness mode = Brightness.light,
  double scale = 1,
}) => ProviderScope(
  overrides: [
    addressRepositoryProvider.overrideWithValue(repository),
    authControllerProvider.overrideWith(SignedIn.new),
  ],
  child: MaterialApp(
    theme: buildAppTheme(brightness: mode),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: page,
  ),
);
Future<void> menu(WidgetTester tester, String label, String action) async {
  await tester.tap(find.byTooltip('Kelola $label'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'address CRUD, primary switch and deletion stay on server result',
    (tester) async {
      final repo = FakeAddresses();
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();
      expect(find.text('Rumah'), findsOneWidget);
      expect(find.text('Utama'), findsOneWidget);
      await tester.tap(find.byTooltip('Tambah alamat'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Kantor');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Jl. Kantor Nomor 20, Depok',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'Lantai satu');
      await tester.ensureVisible(find.text('Simpan alamat'));
      await tester.tap(find.text('Simpan alamat'));
      await tester.pumpAndSettle();
      expect(repo.saves, 1);
      expect(find.text('Kantor'), findsOneWidget);
      await menu(tester, 'Kantor', 'Ubah');
      await tester.enterText(find.byType(TextFormField).at(0), 'Kos');
      await tester.ensureVisible(find.text('Simpan alamat'));
      await tester.tap(find.text('Simpan alamat'));
      await tester.pumpAndSettle();
      expect(find.text('Kos'), findsOneWidget);
      await menu(tester, 'Kos', 'Jadikan utama');
      expect(repo.items.singleWhere((a) => a.isDefault).label, 'Kos');
      await menu(tester, 'Kos', 'Hapus');
      expect(repo.deletes, 0);
      await tester.tap(find.text('Hapus').last);
      await tester.pumpAndSettle();
      expect(repo.deletes, 1);
      expect(find.text('Kos'), findsNothing);
      expect(repo.items.single.isDefault, true);
    },
  );
  testWidgets('failed delete keeps the visible address', (tester) async {
    final repo = FakeAddresses();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    repo.error = const ApiException(
      code: 'NETWORK_ERROR',
      message: 'Koneksi terputus.',
    );
    await menu(tester, 'Rumah', 'Hapus');
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    expect(find.text('Rumah'), findsOneWidget);
    expect(find.text('Koneksi terputus.'), findsOneWidget);
  });
  testWidgets('validation and busy state prevent invalid and duplicate saves', (
    tester,
  ) async {
    final repo = FakeAddresses()..pending = Completer<void>();
    await tester.pumpWidget(app(repo, page: const AddressEditPage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan alamat'));
    await tester.tap(find.text('Simpan alamat'));
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    await tester.enterText(find.byType(TextFormField).at(0), 'Rumah');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Jl. Rumah Baru Nomor 90',
    );
    await tester.ensureVisible(find.text('Simpan alamat'));
    await tester.tap(find.text('Simpan alamat'));
    await tester.pump();
    await tester.tap(find.text('Menyimpan…'));
    expect(repo.saves, 1);
    repo.pending!.complete();
    await tester.pumpAndSettle();
  });
  test('address pages are limited and old session results cannot overwrite new data', () async {
    final repo = FakeAddresses()
      ..lastPage = 2
      ..next = AddressList(
        items: [savedAddress(id: 2, label: 'Kantor', primary: false)],
        page: 2,
        lastPage: 2,
      );
    final container = ProviderContainer.test(
      overrides: [addressRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(addressesProvider.future);
    await container.read(addressesProvider.notifier).loadMore();
    expect(container.read(addressesProvider).value!.items.length, 2);
    repo.items = [savedAddress(id: 9, label: 'Akun baru')];
    container.read(customerSessionRevisionProvider.notifier).advance();
    await container.read(addressesProvider.future);
    expect(container.read(addressesProvider).value!.items.single.id, 9);
  });
  for (final mode in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('address list and form fit 320 / $mode / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(FakeAddresses(), mode: mode, scale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Tambah alamat'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Simpan alamat'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
