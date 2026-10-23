import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'pelanggan.dart';

class AuthRepository {
  AuthRepository(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  Future<Pelanggan> login({required String noTelp, required String pin}) {
    return _authenticate('/auth/login', {'no_telp': noTelp, 'pin': pin});
  }

  Future<Pelanggan> register({
    required String nama,
    required String noTelp,
    required String alamat,
    required String pin,
  }) {
    return _authenticate('/auth/register', {
      'nama': nama,
      'no_telp': noTelp,
      'alamat': alamat,
      'pin': pin,
    });
  }

  Future<Pelanggan> activate({
    required String noTelp,
    required String noNota,
    required String pin,
  }) {
    return _authenticate('/auth/activate', {
      'no_telp': noTelp,
      'no_nota': noNota,
      'pin': pin,
    });
  }

  Future<Pelanggan> me() async {
    final response = await _client.get('/me');
    return Pelanggan.fromJson(response.asMap);
  }

  Future<Pelanggan> updateMe({String? nama, String? alamat}) async {
    final response = await _client.patch(
      '/me',
      body: {'nama': ?nama, 'alamat': ?alamat},
    );
    return Pelanggan.fromJson(response.asMap);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } on ApiException {
      // Sesi lokal tetap harus berakhir walau token sudah tidak berlaku.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<Pelanggan> _authenticate(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(path, body: body);
    final data = response.asMap;
    final token = data['token'];
    final pelanggan = data['pelanggan'];

    if (token is! String || token.isEmpty || pelanggan is! Map) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Respons server tidak dikenali.',
      );
    }

    await _tokenStorage.save(token);
    return Pelanggan.fromJson(Map<String, dynamic>.from(pelanggan));
  }
}
