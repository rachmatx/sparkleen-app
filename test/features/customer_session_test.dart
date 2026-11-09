import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_repository.dart';

import '../support/auth_fakes.dart';
import '../support/home_fakes.dart';
import '../support/pesanan_fakes.dart';

class _DelayedPage extends FakeTransaksiRepository {
  _DelayedPage()
    : super(
        lastPage: 2,
        results: {
          'aktif:1': [testTransaksi(1)],
        },
      );
  final pendingPage = Completer<TransaksiListResult>();
  @override
  Future<TransaksiListResult> list({
    required String status,
    int page = 1,
    int perPage = 20,
  }) {
    if (page == 2) return pendingPage.future;
    return super.list(status: status, page: page, perPage: perPage);
  }
}

void main() {
  test(
    'new session discards cached active order from the previous account',
    () async {
      final repository = FakeHomeRepository()
        ..pesananAktifResult = testTransaksi(1);
      final container = ProviderContainer.test(
        overrides: [homeRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(pesananAktifProvider, (_, _) {});
      addTearDown(subscription.close);
      expect((await container.read(pesananAktifProvider.future))!.id, 1);
      repository.pesananAktifResult = null;
      container.read(customerSessionRevisionProvider.notifier).advance();
      expect(await container.read(pesananAktifProvider.future), isNull);
    },
  );

  test('late pagination response cannot merge a previous account into a new session', () async {
    final repository = _DelayedPage();
    final container = ProviderContainer.test(
      overrides: [transaksiRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(pesananControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(pesananControllerProvider.future);
    final oldPage = container
        .read(pesananControllerProvider.notifier)
        .loadMore();
    repository.results['aktif:1'] = [testTransaksi(2)];
    container.read(customerSessionRevisionProvider.notifier).advance();
    expect(
      (await container.read(pesananControllerProvider.future)).items.single.id,
      2,
    );
    repository.pendingPage.complete(
      TransaksiListResult(
        items: [testTransaksi(999)],
        page: 2,
        lastPage: 2,
        total: 2,
      ),
    );
    await oldPage;
    expect(
      container.read(pesananControllerProvider).value!.items.map((e) => e.id),
      [2],
    );
  });

  test('login and logout advance the customer data session', () async {
    final container = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    final initial = container.read(customerSessionRevisionProvider);
    await container
        .read(authControllerProvider.notifier)
        .login(noTelp: testPelanggan.noTelp, pin: '654321');
    expect(
      container.read(customerSessionRevisionProvider),
      greaterThan(initial),
    );
    final signedIn = container.read(customerSessionRevisionProvider);
    await container.read(authControllerProvider.notifier).logout();
    expect(
      container.read(customerSessionRevisionProvider),
      greaterThan(signedIn),
    );
  });
  test('expired session during profile update does not restore an authenticated user', () async {
    final storage = FakeTokenStorage('expired-demo');
    final repository = FakeAuthRepository()
      ..updateError = const ApiException(
        code: 'AUTH_INVALID_TOKEN',
        message: 'Sesi berakhir.',
        statusCode: 401,
      );
    final container = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    await expectLater(
      container
          .read(authControllerProvider.notifier)
          .updateProfile(nama: 'Nama Baru', alamat: 'Alamat Baru'),
      throwsA(isA<ApiException>()),
    );
    expect(storage.token, isNull);
    expect(
      container.read(authControllerProvider).value,
      isA<AuthUnauthenticated>(),
    );
  });
}
