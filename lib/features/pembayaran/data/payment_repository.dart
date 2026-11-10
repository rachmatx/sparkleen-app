import '../../../core/api/api_client.dart';

class PaymentSnapshot {
  const PaymentSnapshot({
    required this.status,
    required this.enabled,
    required this.amount,
    required this.remaining,
    this.method,
    this.expiresAt,
    this.detail = const {},
  });
  final String status;
  final bool enabled;
  final int amount;
  final int remaining;
  final String? method;
  final DateTime? expiresAt;
  final Map<String, dynamic> detail;
  bool get active =>
      const {'PROCESSING', 'PENDING', 'EXPIRED'}.contains(status);
  factory PaymentSnapshot.fromJson(Map<String, dynamic> json) {
    // Unknown contracts fail closed; do not offer a new payment or real instrument.
    final supported =
        json['mode'] == 'SIMULATION' &&
        const {
          'NONE',
          'PROCESSING',
          'PENDING',
          'EXPIRED',
          'REVIEW',
          'SUCCESS',
        }.contains(json['status']);
    return PaymentSnapshot(
      status: supported ? json['status'] as String : 'REVIEW',
      enabled: supported && json['enabled'] == true,
      amount: (json['nominal'] as num?)?.toInt() ?? 0,
      remaining: (json['sisa'] as num?)?.toInt() ?? 0,
      method: json['metode'] as String?,
      expiresAt: DateTime.tryParse(json['expired_at']?.toString() ?? ''),
      detail: supported && json['payment_detail'] is Map
          ? Map<String, dynamic>.from(json['payment_detail'] as Map)
          : const {},
    );
  }
}

class PaymentRepository {
  PaymentRepository(this._client);
  final ApiClient _client;
  String _path(int id) => '/transaksi/$id/pembayaran';
  Future<PaymentSnapshot> load(int id) async =>
      PaymentSnapshot.fromJson((await _client.get(_path(id))).asMap);
  Future<PaymentSnapshot> start(int id, String method) async =>
      PaymentSnapshot.fromJson(
        (await _client.post(_path(id), body: {'metode': method})).asMap,
      );
  Future<PaymentSnapshot> sync(int id) async => PaymentSnapshot.fromJson(
    (await _client.post('${_path(id)}/sinkronisasi')).asMap,
  );
  Future<PaymentSnapshot> cancel(int id) async => PaymentSnapshot.fromJson(
    (await _client.post('${_path(id)}/batal')).asMap,
  );
}
