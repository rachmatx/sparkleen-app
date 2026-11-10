// Opt-in real HTTP/SQL integration. Only fictional localhost fixtures are allowed.
import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_client.dart';
import 'package:sparkleen_mobile/core/api/api_config.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/features/auth/data/auth_repository.dart';
import 'package:sparkleen_mobile/features/jemput/data/pickup_repository.dart';
import 'package:sparkleen_mobile/features/loyalitas/data/loyalty_repository.dart';
import 'package:sparkleen_mobile/features/notifikasi/data/notification_repository.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_repository.dart';

import '../test/support/auth_fakes.dart';

void main() {
  testWidgets(
    'real HTTP: points discount → cashier payment → inbox → account isolation',
    (tester) async {
      await tester.runAsync(() async {
        final root = Platform.environment['LAUNDRY_TEST_ROOT'];
        final php = Platform.environment['TEST_PHP_BIN'];
        if (root == null ||
            php == null ||
            ![
              '127.0.0.1',
              'localhost',
            ].contains(Uri.parse(ApiConfig.baseUrl).host)) {
          fail('Disposable localhost fixture configuration required.');
        }
        final previous = HttpOverrides.current;
        HttpOverrides.global = null;
        addTearDown(() => HttpOverrides.global = previous);
        final storage = FakeTokenStorage();
        final client = ApiClient(tokenStorage: storage);
        final auth = AuthRepository(client, storage);
        final loyalty = LoyaltyRepository(client);
        final inbox = NotificationRepository(client);
        final orders = TransaksiRepository(client);
        await auth.login(noTelp: '081298765432', pin: '654321');
        expect((await loyalty.summary()).balance, 100);
        expect(await inbox.unread(), 0);
        final quote = await loyalty.quote(1);
        expect(quote.total, 35000);
        expect(quote.earned, 3);
        final redeemed = await loyalty.redeem(
          1,
          points: 20,
          expectedTotal: 35000,
          requestId: 'fixture-http-redemption-1',
        );
        expect(redeemed.balance, 79);
        expect(redeemed.total, 29000);
        expect(
          (await loyalty.redeem(
            1,
            points: 20,
            expectedTotal: 35000,
            requestId: 'fixture-http-redemption-1',
          )).balance,
          79,
        );
        expect((await auth.me()).poin, 79);
        expect((await orders.nota(1)).grandTotal, 29000);
        expect((await loyalty.summary()).history.map((e) => e.delta), [
          -1,
          -20,
        ]);
        final first = await inbox.list();
        expect(first.items.length, 1);
        expect(first.items.single.category, 'loyalty');
        await inbox.read(first.items.single.id);
        expect(await inbox.unread(), 0);
        Future<void> cashier() async {
          final result = await Process.run(php, [
            'tools/mobile_demo.php',
            'cashier-update',
          ], workingDirectory: root);
          expect(result.exitCode, 0, reason: result.stderr.toString());
        }

        await cashier();
        expect((await orders.detail(1)).sudahLunas, true);
        expect((await orders.detail(1)).pembayaran.single.nominalBayar, 29000);
        final updates = await inbox.list();
        expect(updates.items.length, 3);
        expect(updates.unread, 2);
        await inbox.readAll(first.latestId);
        expect(await inbox.unread(), 2);
        await inbox.readAll(updates.latestId);
        expect(await inbox.unread(), 0);
        await cashier();
        expect((await inbox.list()).items.length, 3);
        final pickup = PickupRepository(client);
        final tomorrow = DateTime.now().toUtc().add(
          const Duration(hours: 7, days: 1),
        );
        final date =
            '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        final request = await pickup.create(
          serviceId: 1,
          weight: 4,
          address: 'Jl. Pengujian Tahap Empat Nomor 10',
          date: date,
          slot: 'siang',
        );
        for (final action in ['proses', 'konfirmasi']) {
          final result = await Process.run(php, [
            'tools/pickup_demo.php',
            action,
            '${request.id}',
          ], workingDirectory: root);
          expect(result.exitCode, 0, reason: result.stderr.toString());
          expect(jsonDecode(result.stdout as String), isA<Map>());
        }
        expect((await loyalty.summary()).balance, 82);
        expect((await inbox.list()).items.length, 7);
        await auth.logout();
        await auth.register(
          nama: 'Akun Tahap Empat Kedua',
          noTelp: '081299998877',
          alamat: 'Jl. Pengujian Akun Kedua Nomor 20',
          pin: '123456',
        );
        expect((await loyalty.summary()).balance, 0);
        expect((await loyalty.summary()).history, isEmpty);
        expect((await inbox.list()).items, isEmpty);
        for (final call in [
          () => loyalty.quote(1),
          () => loyalty.redeem(
            1,
            points: 1,
            expectedTotal: 29000,
            requestId: 'fixture-other-account-1',
          ),
          () => inbox.read(first.items.single.id),
        ]) {
          await expectLater(
            call(),
            throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', 404),
            ),
          );
        }
      });
    },
  );
}
