import '../../../core/api/api_client.dart';

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.address,
    this.landmark = '',
    this.isDefault = false,
  });
  final int id;
  final String label, address, landmark;
  final bool isDefault;
  factory CustomerAddress.fromJson(Map<String, dynamic> json) =>
      CustomerAddress(
        id: (json['id_alamat'] as num).toInt(),
        label: json['label'] as String,
        address: json['alamat'] as String,
        landmark: json['patokan'] as String? ?? '',
        isDefault: json['is_default'] == true,
      );
}

class AddressList {
  const AddressList({required this.items, this.page = 1, this.lastPage = 1});
  final List<CustomerAddress> items;
  final int page, lastPage;
}

class AddressRepository {
  AddressRepository(this.client);
  final ApiClient client;
  Future<AddressList> list({int page = 1}) async {
    final r = await client.get(
      '/alamat',
      queryParameters: {'page': page, 'per_page': 20},
    );
    return AddressList(
      items: r.asList
          .whereType<Map>()
          .map((v) => CustomerAddress.fromJson(Map<String, dynamic>.from(v)))
          .toList(),
      page: (r.meta['page'] as num?)?.toInt() ?? page,
      lastPage: (r.meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  Future<void> save({
    int? id,
    required String label,
    required String address,
    required String landmark,
    required bool isDefault,
  }) async {
    final body = {
      'label': label,
      'alamat': address,
      'patokan': landmark,
      'is_default': isDefault,
    };
    if (id == null) {
      await client.post('/alamat', body: body);
    } else {
      await client.patch('/alamat/$id', body: body);
    }
  }

  Future<CustomerAddress> get(int id) async =>
      CustomerAddress.fromJson((await client.get('/alamat/$id')).asMap);
  Future<void> primary(int id) async {
    await client.post('/alamat/$id/utama');
  }

  Future<void> delete(int id) async {
    await client.delete('/alamat/$id');
  }
}
