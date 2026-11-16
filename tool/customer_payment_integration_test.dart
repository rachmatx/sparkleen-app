// Explicit opt-in: only disposable localhost servers and fictional merchant keys.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_client.dart';
import 'package:sparkleen_mobile/core/api/api_config.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/features/auth/data/auth_repository.dart';
import 'package:sparkleen_mobile/features/pembayaran/data/payment_repository.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_repository.dart';

import '../test/support/auth_fakes.dart';

void main() {
  testWidgets(
    'real Dart → Laundry → Payment API: resume, cancel, lost callback recovery, account isolation',
    (tester) async {
      await tester.runAsync(() async {
        final gateway = Uri.parse(
          Platform.environment['PAYMENT_TEST_URL'] ?? '',
        );
        if (![
              '127.0.0.1',
              'localhost',
            ].contains(Uri.parse(ApiConfig.baseUrl).host) ||
            !['127.0.0.1', 'localhost'].contains(gateway.host)) {
          fail('Disposable localhost servers required.');
        }
        final old = HttpOverrides.current;
        HttpOverrides.global = null;
        addTearDown(() => HttpOverrides.global = old);
        final storage = FakeTokenStorage();
        final client = ApiClient(tokenStorage: storage);
        final auth = AuthRepository(client, storage);
        final payments = PaymentRepository(client);
        await auth.login(noTelp: '081298765432', pin: '654321');
        expect((await payments.load(1)).status, 'NONE');
        final bank = await payments.start(1, 'TRANSFER');
        expect(bank.detail['account_number'], 'DEMO-NOT-A-BANK-ACCOUNT');
        expect((await payments.cancel(1)).status, 'NONE');
        final qr = await payments.start(1, 'QRIS');
        expect(qr.status, 'PENDING');
        expect(qr.amount, 35000);
        expect(qr.detail['qr_image'], startsWith('data:image/png;base64,'));
        expect(
          (await payments.start(1, 'QRIS')).detail['simulation_code'],
          qr.detail['simulation_code'],
        );
        expect((await payments.sync(1)).status, 'PENDING');
        await auth.logout();
        await auth.register(
          nama: 'Akun Pembayaran Kedua',
          noTelp: '081299998877',
          alamat: 'Jl. Pengujian Nomor 20',
          pin: '123456',
        );
        for (final call in [
          () => payments.load(1),
          () => payments.start(1, 'QRIS'),
          () => payments.sync(1),
          () => payments.cancel(1),
        ]) {
          await expectLater(
            call(),
            throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', 404),
            ),
          );
        }
        await auth.logout();
        await auth.login(noTelp: '081298765432', pin: '654321');
        // The merchant credential exists only in this opt-in fixture, never shipped UI.
        final http = HttpClient();
        try {
          final request = await http.postUrl(
            gateway.resolve('${qr.detail['simulation_code']}/pay'),
          );
          request.headers.set(
            'X-Api-Key',
            Platform.environment['PAYMENT_TEST_KEY']!,
          );
          request.headers.contentType = ContentType.json;
          request.write('{}');
          final response = await request.close();
          expect(
            response.statusCode,
            200,
            reason: await utf8.decoder.bind(response).join(),
          );
        } finally {
          http.close(force: true);
        }
        // CALLBACK_URL is deliberately blank: GET local stays pending until signed sync.
        expect((await payments.load(1)).status, 'PENDING');
        expect((await payments.sync(1)).status, 'SUCCESS');
        expect((await payments.sync(1)).status, 'SUCCESS');
        expect((await payments.cancel(1)).status, 'SUCCESS');
        final order = await TransaksiRepository(client).detail(1);
        expect(order.sudahLunas, true);
        expect(order.pembayaran.length, 1);
        expect(order.pembayaran.single.nominalBayar, 35000);
      });
    },
  );
}
