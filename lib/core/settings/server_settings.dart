import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_config.dart';

class ServerSettings {
  const ServerSettings();
  static const _key = 'sparkleen_preview_server';
  Future<String> load() async {
    if (!ApiConfig.isPreview) return ApiConfig.baseUrl;
    try {
      final value = await const FlutterSecureStorage().read(key: _key);
      return value == null ? ApiConfig.baseUrl : validateServerAddress(value);
    } on Object {
      return ApiConfig.baseUrl;
    }
  }

  Future<void> save(String address) => const FlutterSecureStorage().write(
    key: _key,
    value: validateServerAddress(address),
  );
}

String validateServerAddress(
  String input, {
  bool preview = ApiConfig.isPreview,
}) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      !['http', 'https'].contains(uri.scheme)) {
    throw const FormatException(
      'Isi alamat server lengkap, tanpa /api/v1, akun, atau parameter.',
    );
  }
  if (uri.scheme == 'http') {
    final parts = uri.host.split('.').map(int.tryParse).toList();
    final ipv4 =
        parts.length == 4 &&
        parts.every((n) => n != null && n >= 0 && n <= 255);
    final private =
        uri.host == 'localhost' ||
        (ipv4 &&
            (parts[0] == 10 ||
                parts[0] == 127 ||
                (parts[0] == 192 && parts[1] == 168) ||
                (parts[0] == 172 && parts[1]! >= 16 && parts[1]! <= 31)));
    if (!preview || !private) {
      throw const FormatException(
        'HTTP hanya untuk IP laptop di jaringan lokal pada versi pengujian. Gunakan HTTPS untuk server internet.',
      );
    }
  }
  return uri.replace(path: '').toString().replaceFirst(RegExp(r'/$'), '');
}

final initialServerAddressProvider = Provider<String>(
  (ref) => ApiConfig.baseUrl,
);
final serverAddressProvider = NotifierProvider<ServerAddress, String>(
  ServerAddress.new,
);

class ServerAddress extends Notifier<String> {
  @override
  String build() => ref.watch(initialServerAddressProvider);
  void change(String address) => state = address;
}
