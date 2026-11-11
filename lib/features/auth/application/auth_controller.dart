import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/security/biometric_service.dart';
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

class AuthLocked extends AuthState {
  const AuthLocked();
}

class AuthSessionUnavailable extends AuthState {
  const AuthSessionUnavailable(this.error);
  final Object error;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);
final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  int _epoch = 0;
  bool _unlocked = false;
  @override
  Future<AuthState> build() async {
    ref.watch(authRepositoryProvider);
    ref.read(apiClientProvider).onUnauthorized = _handleUnauthorized;
    final epoch = ++_epoch;
    final generation = _storage.generation;
    try {
      final token = await _storage.read();
      if (!ref.mounted || epoch != _epoch || generation != _storage.generation) {
        return const AuthUnauthenticated();
      }
      if (token == null || token.isEmpty) {
        _storage.sessionLocked = false;
        return const AuthUnauthenticated();
      }
      final settings = await ref.read(biometricServiceProvider).settings(token);
      if (!ref.mounted || epoch != _epoch || generation != _storage.generation) {
        return const AuthUnauthenticated();
      }
      if (settings.enabled && !_unlocked) {
        _storage.sessionLocked = true;
        return const AuthLocked();
      }
      _storage.sessionLocked = false;
      return await _resume();
    } on Object catch (error) {
      return AuthSessionUnavailable(error);
    }
  }

  Future<AuthState> _resume() async {
    final epoch = _epoch;
    final generation = _storage.generation;
    try {
      return AuthAuthenticated(await _repository.me());
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        if (ref.mounted &&
            epoch == _epoch &&
            generation == _storage.generation) {
          await _storage.clear();
          _unlocked = false;
        }
        return const AuthUnauthenticated();
      }
      return AuthSessionUnavailable(error);
    } on Object catch (error) {
      return AuthSessionUnavailable(error);
    }
  }

  Future<void> retrySession() async {
    final epoch = ++_epoch;
    state = const AsyncLoading();
    try {
      if (!_unlocked) {
        final token = await _storage.read();
        if (token == null) {
          if (ref.mounted && epoch == _epoch) {
            state = const AsyncData(AuthUnauthenticated());
          }
          return;
        }
        final settings = await ref
            .read(biometricServiceProvider)
            .settings(token);
        if (settings.enabled) {
          _storage.sessionLocked = true;
          if (ref.mounted && epoch == _epoch) {
            state = const AsyncData(AuthLocked());
          }
          return;
        }
      }
    } on Object catch (error) {
      if (ref.mounted && epoch == _epoch) {
        state = AsyncData(AuthSessionUnavailable(error));
      }
      return;
    }
    final next = await _resume();
    if (ref.mounted && epoch == _epoch) state = AsyncData(next);
  }

  Future<void> unlock() async {
    final epoch = _epoch;
    final token = await _storage.read();
    if (token == null) return;
    if (!await ref
        .read(biometricServiceProvider)
        .authenticate('Buka sesi Sparkleen dengan biometrik perangkat')) {
      return;
    }
    if (!ref.mounted || epoch != _epoch || token != await _storage.read()) {
      return;
    }
    _unlocked = true;
    _storage.sessionLocked = false;
    await retrySession();
  }

  void lock() {
    if (state.value is! AuthAuthenticated) return;
    _epoch++;
    _unlocked = false;
    _storage.sessionLocked = true;
    ref.read(customerSessionRevisionProvider.notifier).advance();
    state = const AsyncData(AuthLocked());
  }

  Future<void> login({required String noTelp, required String pin}) =>
      _run(() => _repository.login(noTelp: noTelp, pin: pin));
  Future<void> register({
    required String nama,
    required String noTelp,
    required String alamat,
    required String pin,
  }) => _run(
    () => _repository.register(
      nama: nama,
      noTelp: noTelp,
      alamat: alamat,
      pin: pin,
    ),
  );
  Future<void> activate({
    required String noTelp,
    required String noNota,
    required String pin,
  }) => _run(
    () => _repository.activate(noTelp: noTelp, noNota: noNota, pin: pin),
  );
  Future<void> refreshMe() => _updatePelanggan(_repository.me);
  Future<void> updateProfile({required String nama, required String alamat}) =>
      _updatePelanggan(() => _repository.updateMe(nama: nama, alamat: alamat));
  Future<void> _updatePelanggan(Future<Pelanggan> Function() action) async {
    final epoch = _epoch;
    final revision = ref.read(customerSessionRevisionProvider);
    // Preserve the visible profile during refresh and on temporary network failure.
    try {
      final person = await action();
      if (ref.mounted &&
          epoch == _epoch &&
          revision == ref.read(customerSessionRevisionProvider)) {
        state = AsyncData(AuthAuthenticated(person));
      }
    } on ApiException catch (error) {
      if (error.isUnauthorized && ref.mounted && epoch == _epoch) {
        await _handleUnauthorized();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final epoch = ++_epoch;
    _storage.generation++;
    try {
      await _repository.logout();
    } finally {
      if (ref.mounted && epoch == _epoch) {
        await _storage.clear();
        if (ref.mounted && epoch == _epoch) {
          _unlocked = false;
          _storage.sessionLocked = false;
          state = const AsyncData(AuthUnauthenticated());
          ref.read(customerSessionRevisionProvider.notifier).advance();
          ref.invalidate(biometricSettingsProvider);
        }
      }
    }
  }

  Future<void> _run(Future<Pelanggan> Function() action) async {
    final epoch = ++_epoch;
    _storage.generation++;
    state = const AsyncLoading();
    try {
      final person = await action();
      if (ref.mounted && epoch == _epoch) {
        _storage.sessionLocked = false;
        _unlocked = true;
        ref.read(customerSessionRevisionProvider.notifier).advance();
        state = AsyncData(AuthAuthenticated(person));
      }
    } catch (error, stack) {
      if (ref.mounted && epoch == _epoch) {
        state = AsyncError<AuthState>(error, stack);
      }
      rethrow;
    }
  }

  Future<void> _handleUnauthorized() async {
    _epoch++;
    await _storage.clear();
    _unlocked = false;
    if (!ref.mounted) return;
    state = const AsyncData(AuthUnauthenticated());
    ref.read(customerSessionRevisionProvider.notifier).advance();
  }
}
