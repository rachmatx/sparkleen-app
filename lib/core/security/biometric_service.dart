import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../api/api_exception.dart';
import '../providers.dart';
import '../storage/token_storage.dart';

class BiometricSettings {
  const BiometricSettings({this.enabled = false, this.payments = false});
  final bool enabled, payments;
}

class BiometricService {
  BiometricService(this.storage, {MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('sparkleen/security');
  final TokenStorage storage;
  final MethodChannel _channel;
  Future<BiometricSettings> settings(String token) async {
    final raw = await storage.readBiometricBinding();
    if (raw == null) return const BiometricSettings();
    try {
      final data = jsonDecode(raw);
      return data is Map && data['token'] == token
          ? BiometricSettings(enabled: true, payments: data['payments'] == true)
          : const BiometricSettings();
    } on FormatException {
      throw const ApiException(
        code: 'BIOMETRIC_SETTINGS_INVALID',
        message: 'Pengaturan keamanan belum dapat dibaca. Masuk kembali dengan PIN akun.',
      );
    }
  }

  Future<bool> available() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('available') == true;
    } on Object {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    if (!await available()) {
      throw const ApiException(
        code: 'BIOMETRIC_UNAVAILABLE',
        message: 'Biometrik kuat belum tersedia. Daftarkan sidik jari di pengaturan Android atau masuk ulang dengan PIN akun.',
      );
    }
    try {
      return await _channel.invokeMethod<bool>('authenticate', {
            'reason': reason,
          }) ==
          true;
    } on PlatformException {
      throw const ApiException(
        code: 'BIOMETRIC_FAILED',
        message: 'Verifikasi belum berhasil atau perangkat terkunci sementara. Coba lagi atau masuk dengan PIN akun.',
      );
    }
  }

  Future<void> enable(String token) async {
    if (!await authenticate('Aktifkan akses biometrik untuk Sparkleen')) {
      throw const ApiException(
        code: 'BIOMETRIC_CANCELLED',
        message: 'Aktivasi biometrik dibatalkan.',
      );
    }
    if (await storage.read() != token) {
      throw const ApiException(
        code: 'SESSION_CHANGED',
        message: 'Sesi berubah. Masuk kembali.',
      );
    }
    await storage.writeBiometricBinding(
      jsonEncode({'token': token, 'payments': true}),
    );
  }

  Future<void> disable(String token) async {
    if (!await authenticate('Nonaktifkan akses biometrik Sparkleen')) {
      throw const ApiException(
        code: 'BIOMETRIC_CANCELLED',
        message: 'Perubahan dibatalkan.',
      );
    }
    if (await storage.read() != token) return;
    await storage.clearBiometricBinding();
  }

  Future<void> paymentPreference(String token, bool enabled) async {
    if (!await authenticate('Ubah keamanan pembayaran Sparkleen')) {
      throw const ApiException(
        code: 'BIOMETRIC_CANCELLED',
        message: 'Perubahan dibatalkan.',
      );
    }
    if (await storage.read() != token) return;
    await storage.writeBiometricBinding(
      jsonEncode({'token': token, 'payments': enabled}),
    );
  }

  Future<bool> confirmPayment(String reason) async {
    final token = await storage.read();
    if (token == null) return false;
    final config = await settings(token);
    return !config.enabled || !config.payments || await authenticate(reason);
  }
}

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(ref.watch(tokenStorageProvider)),
);
final biometricSettingsProvider = FutureProvider<BiometricSettings>((
  ref,
) async {
  ref.watch(customerSessionRevisionProvider);
  final token = await ref.watch(tokenStorageProvider).read();
  return token == null
      ? const BiometricSettings()
      : ref.watch(biometricServiceProvider).settings(token);
});
final biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricServiceProvider).available(),
);
