// Explicit opt-in live integration check. Uses only a local disposable test API.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_client.dart';
import 'package:sparkleen_mobile/core/api/api_config.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/features/auth/data/auth_repository.dart';
import 'package:sparkleen_mobile/features/home/data/home_repository.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_repository.dart';

import '../test/support/auth_fakes.dart';

void main() {
  testWidgets(
    'Flutter repositories use live local customer API and cashier updates',
    (tester) async {
      await tester.runAsync(() async {
        final uri = Uri.parse(ApiConfig.baseUrl);
        if (!['127.0.0.1', 'localhost'].contains(uri.host)) {
          fail('This tool may only target a LOCAL disposable test API.');
        }
        // Ordinary widget tests retain their isolated HTTP override. This opt-in
        // tool intentionally talks to our local test server via real Dio HTTP.
        final previous = HttpOverrides.current;
        HttpOverrides.global = null;
        addTearDown(() => HttpOverrides.global = previous);
        final storage = FakeTokenStorage();
        final client = ApiClient(tokenStorage: storage);
        final auth = AuthRepository(client, storage);
        final home = HomeRepository(client);
        final orders = TransaksiRepository(client);
        final customer = await auth.login(
          noTelp: '6281298765432',
          pin: '654321',
        );
        expect(customer.id, 1);
        expect((await auth.me()).id, customer.id);
        expect(await home.layanan(), isNotEmpty);
        expect((await home.outlet()).nama, isNotEmpty);
        final listing = await orders.list(status: 'semua', perPage: 1);
        expect(listing.items, hasLength(1));
        expect(listing.total, greaterThanOrEqualTo(1));
        final id = listing.items.first.id;
        final before = await orders.detail(id);
        expect(before.items, isNotEmpty);
        final updatedProfile = await auth.updateMe(
          nama: 'Pelanggan Integrasi',
          alamat: 'Jl. Pengujian Integrasi 10',
        );
        expect(updatedProfile.nama, 'Pelanggan Integrasi');
        expect((await auth.me()).alamat, 'Jl. Pengujian Integrasi 10');
        final root = Platform.environment['LAUNDRY_TEST_ROOT'];
        final php = Platform.environment['TEST_PHP_BIN'];
        if (root == null || php == null) {
          fail(
            'Set LAUNDRY_TEST_ROOT and TEST_PHP_BIN to run the cashier fixture.',
          );
        }
        final mutation = await Process.run(php, [
          'tools/mobile_demo.php',
          'cashier-update',
        ], workingDirectory: root);
        expect(mutation.exitCode, 0, reason: '${mutation.stderr}');
        final after = await orders.detail(id);
        expect(after.status, 'selesai');
        expect(after.sudahLunas, isTrue);
        final nota = await orders.nota(id);
        expect(nota.grandTotal, after.grandTotal);
        expect(nota.statusPembayaran, 'lunas');
        final rawNota = await client.get('/transaksi/$id/nota');
        expect(rawNota.asMap.containsKey('pin_pengambilan'), isFalse);
        await auth.logout();
        expect(storage.token, isNull);
        await expectLater(
          auth.me(),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 401),
          ),
        );
        final second = await auth.register(
          nama: 'Pelanggan Kedua',
          noTelp: '081288887777',
          alamat: 'Alamat Pelanggan Kedua',
          pin: '123456',
        );
        expect(second.id, isNot(customer.id));
        await expectLater(
          orders.detail(id),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 404),
          ),
        );
        await expectLater(
          orders.nota(id),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 404),
          ),
        );
        expect((await orders.list(status: 'semua')).items, isEmpty);
        await auth.logout();
      });
    },
  );
}
