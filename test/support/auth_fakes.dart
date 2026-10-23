import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/storage/token_storage.dart';
import 'package:sparkleen_mobile/features/auth/data/auth_repository.dart';
import 'package:sparkleen_mobile/features/auth/data/pelanggan.dart';

const testPelanggan = Pelanggan(
  id: 12,
  kode: 'PLG012',
  nama: 'Budi Santoso',
  noTelp: '6281298765432',
  alamat: 'Jl. Merdeka No. 10',
  poin: 15,
  totalTransaksi: 4,
);

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> save(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

class FakeAuthRepository implements AuthRepository {
  Pelanggan pelanggan = testPelanggan;

  ApiException? loginError;
  ApiException? registerError;
  ApiException? activateError;
  ApiException? meError;
  ApiException? updateError;

  int loginCalls = 0;
  int registerCalls = 0;
  int activateCalls = 0;
  int meCalls = 0;
  int updateCalls = 0;
  int logoutCalls = 0;

  String? lastPhone;
  String? lastPin;
  String? lastNoNota;
  String? lastNama;
  String? lastAlamat;

  @override
  Future<Pelanggan> login({
    required String noTelp,
    required String pin,
  }) async {
    loginCalls++;
    lastPhone = noTelp;
    lastPin = pin;
    final error = loginError;
    if (error != null) throw error;
    return pelanggan;
  }

  @override
  Future<Pelanggan> register({
    required String nama,
    required String noTelp,
    required String alamat,
    required String pin,
  }) async {
    registerCalls++;
    lastNama = nama;
    lastPhone = noTelp;
    lastAlamat = alamat;
    lastPin = pin;
    final error = registerError;
    if (error != null) throw error;
    return pelanggan;
  }

  @override
  Future<Pelanggan> activate({
    required String noTelp,
    required String noNota,
    required String pin,
  }) async {
    activateCalls++;
    lastPhone = noTelp;
    lastNoNota = noNota;
    lastPin = pin;
    final error = activateError;
    if (error != null) throw error;
    return pelanggan;
  }

  @override
  Future<Pelanggan> me() async {
    meCalls++;
    final error = meError;
    if (error != null) throw error;
    return pelanggan;
  }

  @override
  Future<Pelanggan> updateMe({String? nama, String? alamat}) async {
    updateCalls++;
    lastNama = nama;
    lastAlamat = alamat;
    final error = updateError;
    if (error != null) throw error;
    return pelanggan;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}
