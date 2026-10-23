import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';

import '../support/auth_fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late FakeTokenStorage storage;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAuthRepository();
    storage = FakeTokenStorage();
    container = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  test('tanpa token langsung unauthenticated tanpa memanggil /me', () async {
    final state = await container.read(authControllerProvider.future);

    expect(state, isA<AuthUnauthenticated>());
    expect(repository.meCalls, 0);
  });

  test('token valid memuat profil lewat /me', () async {
    storage.token = 'token-abc';

    final state = await container.read(authControllerProvider.future);

    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).pelanggan.nama, 'Budi Santoso');
    expect(repository.meCalls, 1);
  });

  test('token ditolak 401 dihapus dan menjadi unauthenticated', () async {
    storage.token = 'token-kedaluwarsa';
    repository.meError = const ApiException(
      code: 'AUTH_INVALID_TOKEN',
      message: 'Sesi Anda sudah berakhir.',
      statusCode: 401,
    );

    final state = await container.read(authControllerProvider.future);

    expect(state, isA<AuthUnauthenticated>());
    expect(storage.token, isNull);
  });

  test('login sukses menyimpan state authenticated', () async {
    await container.read(authControllerProvider.future);

    await container
        .read(authControllerProvider.notifier)
        .login(noTelp: '081298765432', pin: '654321');

    final state = container.read(authControllerProvider).requireValue;
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).pelanggan.id, testPelanggan.id);
    expect(repository.loginCalls, 1);
    expect(repository.lastPhone, '081298765432');
    expect(repository.lastPin, '654321');
  });

  test('login gagal menyimpan error fields untuk validasi input', () async {
    repository.loginError = const ApiException(
      code: 'VALIDATION_ERROR',
      message: 'Data yang dikirim belum valid.',
      statusCode: 422,
      fields: {
        'pin': ['PIN harus 6 digit angka.'],
      },
    );
    await container.read(authControllerProvider.future);

    await expectLater(
      container
          .read(authControllerProvider.notifier)
          .login(noTelp: '081298765432', pin: '123'),
      throwsA(isA<ApiException>()),
    );

    final state = container.read(authControllerProvider);
    expect(state.hasError, isTrue);
    expect(
      (state.error! as ApiException).fieldError('pin'),
      'PIN harus 6 digit angka.',
    );
    expect(state.value, isA<AuthUnauthenticated>());
  });

  test('logout memanggil repository dan menjadi unauthenticated', () async {
    storage.token = 'token-abc';
    await container.read(authControllerProvider.future);

    await container.read(authControllerProvider.notifier).logout();

    expect(repository.logoutCalls, 1);
    expect(
      container.read(authControllerProvider).requireValue,
      isA<AuthUnauthenticated>(),
    );
  });

  test('update profil memperbarui data pelanggan di state', () async {
    storage.token = 'token-abc';
    await container.read(authControllerProvider.future);

    await container
        .read(authControllerProvider.notifier)
        .updateProfile(nama: 'Budi Baru', alamat: 'Jl. Melati No. 2');

    expect(repository.updateCalls, 1);
    expect(repository.lastNama, 'Budi Baru');
    expect(repository.lastAlamat, 'Jl. Melati No. 2');
    expect(
      container.read(authControllerProvider).requireValue,
      isA<AuthAuthenticated>(),
    );
  });
}
