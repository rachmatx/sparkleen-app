import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_exception.dart';

class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'sparkleen_token';

  final FlutterSecureStorage _storage;
  bool sessionLocked = false;
  int generation = 0;
  Future<void> _writes = Future.value();
  Future<void> _enqueue(Future<void> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.catchError((Object _) {});
    return result;
  }

  Future<void> saveIfCurrent(String token, int expectedGeneration) async {
    if (generation != expectedGeneration) {
      throw const ApiException(
        code: 'SESSION_CHANGED',
        message: 'Sesi berubah. Coba masuk kembali.',
      );
    }
    await save(token);
  }

  String? requestOrigin;
  static const _biometricKey = 'sparkleen_biometric_binding';
  Future<String?> readBiometricBinding() => _storage.read(key: _biometricKey);
  Future<void> writeBiometricBinding(String value) =>
      _storage.write(key: _biometricKey, value: value);
  Future<void> clearBiometricBinding() => _storage.delete(key: _biometricKey);

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> save(String token) {
    final expected = generation;
    return _enqueue(() async {
      if (generation != expected) {
        throw const ApiException(
          code: 'SESSION_CHANGED',
          message: 'Sesi berubah. Coba masuk kembali.',
        );
      }
      await _storage.delete(key: _biometricKey);
      await _storage.write(key: _tokenKey, value: token);
    });
  }

  Future<void> clear() {
    generation++;
    return _enqueue(() async {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _biometricKey);
      sessionLocked = false;
    });
  }
}
