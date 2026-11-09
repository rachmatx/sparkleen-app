// Explicit opt-in check: real Flutter repositories, local HTTP and disposable DB.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sparkleen_mobile/core/api/api_client.dart';
import 'package:sparkleen_mobile/core/api/api_config.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/features/auth/data/auth_repository.dart';
import 'package:sparkleen_mobile/features/jemput/data/pickup_repository.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_repository.dart';

import '../test/support/auth_fakes.dart';

void main() {
  testWidgets(
    'pickup request → real cashier service → linked order, with account isolation',
    (tester) async {
      await tester.runAsync(() async {
        final uri = Uri.parse(ApiConfig.baseUrl);
        if (!['127.0.0.1', 'localhost'].contains(uri.host)) {
          fail('Only a local disposable backend is allowed.');
        }
        final root = Platform.environment['LAUNDRY_TEST_ROOT'];
        final php = Platform.environment['TEST_PHP_BIN'];
        if (root == null || php == null) {
          fail('LAUNDRY_TEST_ROOT and TEST_PHP_BIN are required.');
        }
        final previous = HttpOverrides.current;
        HttpOverrides.global = null;
        addTearDown(() => HttpOverrides.global = previous);
        final storage = FakeTokenStorage();
        final client = ApiClient(tokenStorage: storage);
        final auth = AuthRepository(client, storage);
        await auth.login(noTelp: '6281298765432', pin: '654321');
        final repository = PickupRepository(client);
        final date = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().toUtc().add(const Duration(hours: 7, days: 1)));
        final request = await repository.create(
          serviceId: 1,
          weight: 4.5,
          address: 'Jl. Jemput Integrasi Nomor 10',
          date: date,
          slot: 'siang',
        );
        expect(request.estimatedPrice, 31500);
        expect(request.transactionId, isNull);
        expect((await repository.list()).items.single.id, request.id);
        await expectLater(
          repository.create(
            serviceId: 1,
            weight: 4.5,
            address: 'Jl. Jemput Integrasi Nomor 10',
            date: date,
            slot: 'siang',
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 409),
          ),
        );
        for (final action in ['proses', 'konfirmasi']) {
          final result = await Process.run(php, [
            'tools/pickup_demo.php',
            action,
            '${request.id}',
          ], workingDirectory: root);
          expect(result.exitCode, 0, reason: result.stderr.toString());
          final output =
              jsonDecode(result.stdout as String) as Map<String, dynamic>;
          expect(
            output['status'],
            action == 'proses' ? 'diproses' : 'dikonfirmasi',
          );
        }
        final accepted = (await repository.list()).items.single;
        expect(accepted.transactionId, isNotNull);
        final orders = TransaksiRepository(client);
        final detail = await orders.detail(accepted.transactionId!);
        expect(detail.totalBerat, 5);
        expect(detail.grandTotal, 35000);
        final nota = await orders.nota(accepted.transactionId!);
        expect(nota.grandTotal, detail.grandTotal);
        final next = await repository.create(
          serviceId: 1,
          weight: 2,
          address: 'Jl. Jemput Integrasi Nomor 10',
          date: date,
          slot: 'sore',
        );
        await repository.cancel(next.id);
        expect((await repository.list()).items.first.status, 'dibatalkan');
        await auth.logout();
        await auth.register(
          nama: 'Pelanggan Jemput Kedua',
          noTelp: '081299998877',
          alamat: 'Jl. Akun Kedua Nomor 20',
          pin: '123456',
        );
        expect((await repository.list()).items, isEmpty);
        await expectLater(
          client.get('/permintaan/${request.id}'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 404),
          ),
        );
        await expectLater(
          client.post('/permintaan/${request.id}/batal'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 404),
          ),
        );
      });
    },
  );
}
