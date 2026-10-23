import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';

import '../support/pesanan_fakes.dart';

void main() {
  test('build memuat halaman pertama scope aktif', () async {
    final repository = FakeTransaksiRepository(
      results: {
        'aktif:1': [testTransaksi(1)],
      },
    );
    final container = ProviderContainer.test(
      overrides: [transaksiRepositoryProvider.overrideWithValue(repository)],
    );

    final state = await container.read(pesananControllerProvider.future);

    expect(repository.calls, [(status: 'aktif', page: 1)]);
    expect(state.items.map((item) => item.id), [1]);
    expect(state.scope, PesananScope.aktif);
  });

  test('ganti scope memuat ulang dari halaman pertama', () async {
    final repository = FakeTransaksiRepository(
      results: {
        'aktif:1': [testTransaksi(1)],
        'selesai:1': [
          testTransaksi(2, status: 'selesai', label: 'Selesai'),
        ],
      },
    );
    final container = ProviderContainer.test(
      overrides: [transaksiRepositoryProvider.overrideWithValue(repository)],
    );
    await container.read(pesananControllerProvider.future);

    await container
        .read(pesananControllerProvider.notifier)
        .load(PesananScope.selesai);

    final state = container.read(pesananControllerProvider).value!;
    expect(repository.calls.last, (status: 'selesai', page: 1));
    expect(state.scope, PesananScope.selesai);
    expect(state.page, 1);
    expect(state.items.map((item) => item.id), [2]);
  });

  test('loadMore menambah item tanpa duplikat', () async {
    final repository = FakeTransaksiRepository(
      lastPage: 2,
      results: {
        'aktif:1': [testTransaksi(1)],
        // Backend bisa menggeser item antar halaman saat data berubah.
        'aktif:2': [testTransaksi(1), testTransaksi(3)],
      },
    );
    final container = ProviderContainer.test(
      overrides: [transaksiRepositoryProvider.overrideWithValue(repository)],
    );
    await container.read(pesananControllerProvider.future);

    await container.read(pesananControllerProvider.notifier).loadMore();

    final state = container.read(pesananControllerProvider).value!;
    expect(repository.calls.last, (status: 'aktif', page: 2));
    expect(state.items.map((item) => item.id), [1, 3]);
    expect(state.page, 2);
    expect(state.hasMore, isFalse);
  });

  test('loadMore tidak memanggil API saat halaman terakhir tercapai', () async {
    final repository = FakeTransaksiRepository(
      results: {
        'aktif:1': [testTransaksi(1)],
      },
    );
    final container = ProviderContainer.test(
      overrides: [transaksiRepositoryProvider.overrideWithValue(repository)],
    );
    await container.read(pesananControllerProvider.future);

    await container.read(pesananControllerProvider.notifier).loadMore();

    expect(repository.calls, [(status: 'aktif', page: 1)]);
  });

  test('refresh mempertahankan scope dan kembali ke halaman pertama', () async {
    final repository = FakeTransaksiRepository(
      lastPage: 2,
      results: {
        'semua:1': [testTransaksi(1)],
        'semua:2': [testTransaksi(2)],
      },
    );
    final container = ProviderContainer.test(
      overrides: [transaksiRepositoryProvider.overrideWithValue(repository)],
    );
    await container.read(pesananControllerProvider.future);
    final controller = container.read(pesananControllerProvider.notifier);
    await controller.load(PesananScope.semua);
    await controller.loadMore();

    await controller.refresh();

    final state = container.read(pesananControllerProvider).value!;
    expect(repository.calls.last, (status: 'semua', page: 1));
    expect(state.scope, PesananScope.semua);
    expect(state.items.map((item) => item.id), [1]);
  });
}
