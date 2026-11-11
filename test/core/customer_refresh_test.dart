import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/sync/customer_refresh.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/auth/data/pelanggan.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/jemput/application/pickup_controller.dart';
import 'package:sparkleen_mobile/features/notifikasi/application/notification_controller.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';

import '../support/auth_fakes.dart';
import '../support/home_fakes.dart';
import '../support/pesanan_fakes.dart';
import '../support/engagement_fakes.dart';
import '../features/pickup_test.dart' show FakePickupRepository;

class _Profile extends FakeAuthRepository {
  Completer<Pelanggan>? pending;
  @override
  Future<Pelanggan> me() async {
    meCalls++;
    return pending?.future ?? pelanggan;
  }
}

void main() {
  test('refresh coalesces requests, updates points and retains selected order filter', () async {
    final repo = _Profile();
    final orders = FakeTransaksiRepository(
      results: {'aktif:1': [], 'selesai:1': []},
    );
    final c = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(FakeTokenStorage('session')),
        authRepositoryProvider.overrideWithValue(repo),
        homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
        transaksiRepositoryProvider.overrideWithValue(orders),
        pickupRepositoryProvider.overrideWithValue(FakePickupRepository()),
        notificationRepositoryProvider.overrideWithValue(FakeNotifications()),
      ],
    );
    await c.read(authControllerProvider.future);
    await c.read(pesananControllerProvider.future);
    await c.read(pesananControllerProvider.notifier).load(PesananScope.selesai);
    repo.pending = Completer();
    final first = c.read(customerRefreshProvider.notifier).refresh();
    final second = c.read(customerRefreshProvider.notifier).refresh();
    expect(identical(first, second), true);
    expect(repo.meCalls, 2);
    repo.pending!.complete(
      const Pelanggan(
        id: 12,
        kode: 'PLG012',
        nama: 'Budi Santoso',
        noTelp: '6281298765432',
        alamat: 'Depok',
        poin: 99,
        totalTransaksi: 4,
      ),
    );
    await first;
    await second;
    expect(
      (c.read(authControllerProvider).value as AuthAuthenticated)
          .pelanggan
          .poin,
      99,
    );
    expect(
      c.read(pesananControllerProvider).value!.scope,
      PesananScope.selesai,
    );
    expect(c.read(customerRefreshProvider).failed, false);
    expect(c.read(customerRefreshProvider).busy, false);
  });
  test('refresh from an old account cannot update a new session', () async {
    final repo = _Profile();
    final c = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(FakeTokenStorage('session')),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    await c.read(authControllerProvider.future);
    repo.pending = Completer();
    final pending = c.read(customerRefreshProvider.notifier).refresh();
    await c.read(authControllerProvider.notifier).logout();
    repo.pending!.complete(testPelanggan);
    await pending;
    expect(c.read(authControllerProvider).value, isA<AuthUnauthenticated>());
  });
}
