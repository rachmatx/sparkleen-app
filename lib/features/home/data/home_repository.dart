import '../../../core/api/api_client.dart';
import '../../pesanan/data/transaksi_ringkas.dart';
import 'layanan.dart';
import 'outlet_info.dart';

class HomeRepository {
  HomeRepository(this._client);

  final ApiClient _client;

  Future<List<Layanan>> layanan() async {
    final response = await _client.get('/layanan');
    return response.asList
        .whereType<Map>()
        .map((item) => Layanan.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<OutletInfo> outlet() async {
    final response = await _client.get('/outlet');
    return OutletInfo.fromJson(response.asMap);
  }

  Future<TransaksiRingkas?> pesananAktif() async {
    final response = await _client.get(
      '/transaksi',
      queryParameters: {'status': 'aktif', 'per_page': 1},
    );
    final items = response.asList;
    if (items.isEmpty) return null;
    final first = items.first;
    return first is Map
        ? TransaksiRingkas.fromJson(Map<String, dynamic>.from(first))
        : null;
  }
}
