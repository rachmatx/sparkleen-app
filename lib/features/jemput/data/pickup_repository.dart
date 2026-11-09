import '../../../core/api/api_client.dart';

class PickupRequest {
  const PickupRequest({
    required this.id,
    required this.status,
    required this.service,
    required this.estimatedWeight,
    required this.estimatedPrice,
    required this.address,
    required this.scheduledAt,
    required this.slot,
    this.note,
    this.rejectionReason,
    this.transactionId,
  });

  final int id;
  final String status;
  final String service;
  final double estimatedWeight;
  final int estimatedPrice;
  final String address;
  final DateTime scheduledAt;
  final String slot;
  final String? note;
  final String? rejectionReason;
  final int? transactionId;

  bool get isActive => status == 'menunggu' || status == 'diproses';
  bool get canCancel => status == 'menunggu';
  String get statusLabel => switch (status) {
    'menunggu' => 'Menunggu konfirmasi',
    'diproses' => 'Penjemputan diproses',
    'dikonfirmasi' => 'Cucian diterima',
    'ditolak' => 'Permintaan ditolak',
    'dibatalkan' => 'Dibatalkan',
    _ => 'Status belum tersedia',
  };
  String get slotLabel => switch (slot) {
    'pagi' => 'Pagi · mulai 08.00 WIB',
    'siang' => 'Siang · mulai 12.00 WIB',
    'sore' => 'Sore · mulai 15.00 WIB',
    _ => slot,
  };
  factory PickupRequest.fromJson(Map<String, dynamic> json) => PickupRequest(
    id: (json['id_permintaan'] as num).toInt(),
    status: json['status'] as String,
    service: json['nama_layanan'] as String? ?? '',
    estimatedWeight: (json['berat_perkiraan'] as num).toDouble(),
    estimatedPrice: (json['estimasi_harga'] as num).toInt(),
    address: json['alamat_jemput'] as String,
    scheduledAt: DateTime.parse(json['tgl_jemput'] as String),
    slot: json['slot_jemput'] as String,
    note: json['catatan'] as String?,
    rejectionReason: json['alasan_penolakan'] as String?,
    transactionId: (json['id_transaksi'] as num?)?.toInt(),
  );
}

class PickupList {
  const PickupList({this.items = const [], this.page = 1, this.lastPage = 1});
  final List<PickupRequest> items;
  final int page;
  final int lastPage;
}

class PickupRepository {
  PickupRepository(this._client);
  final ApiClient _client;

  Future<PickupList> list({int page = 1}) async {
    final response = await _client.get(
      '/permintaan',
      queryParameters: {'page': page, 'per_page': 20},
    );
    return PickupList(
      items: response.asList
          .whereType<Map>()
          .map(
            (item) => PickupRequest.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      page: (response.meta['page'] as num?)?.toInt() ?? page,
      lastPage: (response.meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  Future<PickupRequest> create({
    required int serviceId,
    required double weight,
    required String address,
    required String date,
    required String slot,
    String note = '',
  }) async {
    final response = await _client.post(
      '/permintaan',
      body: {
        'id_layanan': serviceId,
        'berat_perkiraan': weight,
        'alamat_jemput': address,
        'tgl_jemput': date,
        'slot_jemput': slot,
        'catatan': note,
      },
    );
    return PickupRequest.fromJson(response.asMap);
  }

  Future<void> cancel(int id) async {
    await _client.post('/permintaan/$id/batal');
  }
}
