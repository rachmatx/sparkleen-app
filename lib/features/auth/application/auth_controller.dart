import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../data/pelanggan.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.pelanggan);

  final Pelanggan pelanggan;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  @override
  Future<AuthState> build() async {
    ref.read(apiClientProvider).onUnauthorized = _handleUnauthorized;

    final token = await _storage.read();
    if (token == null || token.isEmpty) {
      return const AuthUnauthenticated();
    }

    try {
      return AuthAuthenticated(await _repository.me());
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _storage.clear();
      }
      return const AuthUnauthenticated();
    }
  }

  Future<void> login({required String noTelp, required String pin}) {
    return _run(() => _repository.login(noTelp: noTelp, pin: pin));
  }

  Future<void> register({
    required String nama,
    required String noTelp,
    required String alamat,
    required String pin,
  }) {
    return _run(
      () => _repository.register(
        nama: nama,
        noTelp: noTelp,
        alamat: alamat,
        pin: pin,
      ),
    );
  }

  Future<void> activate({
    required String noTelp,
    required String noNota,
    required String pin,
  }) {
    return _run(
      () => _repository.activate(noTelp: noTelp, noNota: noNota, pin: pin),
    );
  }

  Future<void> refreshMe() {
    return _updatePelanggan(_repository.me);
  }

  Future<void> updateProfile({required String nama, required String alamat}) {
    return _updatePelanggan(
      () => _repository.updateMe(nama: nama, alamat: alamat),
    );
  }

  Future<void> _updatePelanggan(Future<Pelanggan> Function() action) async {
    final previous = state;
    final revision = ref.read(customerSessionRevisionProvider);
    state = const AsyncLoading<AuthState>();
    try {
      final pelanggan = await action();
      if (ref.mounted &&
          ref.read(customerSessionRevisionProvider) == revision) {
        state = AsyncData(AuthAuthenticated(pelanggan));
      }
    } catch (error) {
      if (ref.mounted &&
          ref.read(customerSessionRevisionProvider) == revision) {
        if (error is ApiException && error.isUnauthorized) {
          await _storage.clear();
          if (ref.mounted) {
            state = const AsyncData(AuthUnauthenticated());
            ref.read(customerSessionRevisionProvider.notifier).advance();
          }
        } else {
          state = previous;
        }
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      if (ref.mounted) {
        state = const AsyncData(AuthUnauthenticated());
        ref.read(customerSessionRevisionProvider.notifier).advance();
      }
    }
  }

  Future<void> _run(Future<Pelanggan> Function() action) async {
    state = const AsyncLoading<AuthState>();
    try {
      final pelanggan = await action();
      if (ref.mounted) {
        ref.read(customerSessionRevisionProvider.notifier).advance();
        state = AsyncData(AuthAuthenticated(pelanggan));
      }
    } catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError<AuthState>(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _handleUnauthorized() async {
    await _storage.clear();
    if (!ref.mounted) return;
    if (state.value is! AuthUnauthenticated) {
      state = const AsyncData(AuthUnauthenticated());
      ref.read(customerSessionRevisionProvider.notifier).advance();
    }
  }
}
