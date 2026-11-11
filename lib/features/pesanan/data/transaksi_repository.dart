import '../../../core/api/api_client.dart';
import '../../nota/data/nota_data.dart';
import 'transaksi_detail.dart';
import 'transaksi_ringkas.dart';

class TransaksiListResult {
  const TransaksiListResult({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  final List<TransaksiRingkas> items;
  final int page;
  final int lastPage;
  final int total;
}

class TransaksiRepository {
  TransaksiRepository(this._client);

  final ApiClient _client;

  Future<TransaksiListResult> list({
    required String status,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _client.get(
      '/transaksi',
      queryParameters: {'status': status, 'page': page, 'per_page': perPage},
    );

    final items = response.asList
        .whereType<Map>()
        .map(
          (json) => TransaksiRingkas.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();

    final meta = response.meta;
    return TransaksiListResult(
      items: items,
      page: (meta['page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? page,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<TransaksiDetail> detail(int id) async {
    final response = await _client.get('/transaksi/$id');
    return TransaksiDetail.fromJson(response.asMap);
  }

  Future<NotaData> nota(int id) async {
    final response = await _client.get('/transaksi/$id/nota');
    return NotaData.fromJson(response.asMap);
  }
}
