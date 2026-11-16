import '../../../core/api/api_client.dart';

class PointMovement {
  const PointMovement({
    required this.id,
    required this.orderId,
    required this.delta,
    required this.balanceAfter,
    required this.reason,
    required this.nota,
    this.createdAt,
  });
  final int id, orderId, delta, balanceAfter;
  final String reason, nota;
  final DateTime? createdAt;
  factory PointMovement.fromJson(Map<String, dynamic> json) => PointMovement(
    id: (json['id'] as num).toInt(),
    orderId: (json['order_id'] as num).toInt(),
    delta: (json['delta'] as num).toInt(),
    balanceAfter: (json['balance_after'] as num).toInt(),
    reason: json['reason'] as String? ?? '',
    nota: json['no_nota'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

class LoyaltySummary {
  const LoyaltySummary({
    required this.balance,
    this.value = 300,
    this.history = const [],
    this.page = 1,
    this.lastPage = 1,
  });
  final int balance, value, page, lastPage;
  final List<PointMovement> history;
}

class RedemptionQuote {
  const RedemptionQuote({
    required this.orderId,
    required this.nota,
    required this.balance,
    required this.total,
    required this.earned,
    required this.maxPoints,
    required this.canRedeem,
    this.value = 300,
    this.reason,
    this.redemption,
  });
  final int orderId, balance, total, earned, maxPoints, value;
  final String nota;
  final bool canRedeem;
  final String? reason;
  final Map<String, dynamic>? redemption;
  int correction(int points) =>
      (earned - (total - points * value) ~/ 10000).clamp(0, earned);
  factory RedemptionQuote.fromJson(Map<String, dynamic> json) =>
      RedemptionQuote(
        orderId: (json['order_id'] as num).toInt(),
        nota: json['no_nota'] as String? ?? '',
        balance: (json['balance'] as num).toInt(),
        total: (json['grand_total'] as num).toInt(),
        earned: (json['earned_points'] as num).toInt(),
        maxPoints: (json['max_points'] as num).toInt(),
        canRedeem: json['can_redeem'] == true,
        value: (json['point_value'] as num?)?.toInt() ?? 300,
        reason: json['reason'] as String?,
        redemption: json['redemption'] is Map
            ? Map<String, dynamic>.from(json['redemption'] as Map)
            : null,
      );
}

class LoyaltyRepository {
  LoyaltyRepository(this._client);
  final ApiClient _client;
  Future<LoyaltySummary> summary({int page = 1}) async {
    final response = await _client.get(
      '/loyalitas',
      queryParameters: {'page': page, 'per_page': 20},
    );
    final data = response.asMap;
    return LoyaltySummary(
      balance: (data['balance'] as num).toInt(),
      value: (data['point_value'] as num).toInt(),
      history: (data['history'] as List)
          .whereType<Map>()
          .map((e) => PointMovement.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      page: (response.meta['page'] as num?)?.toInt() ?? page,
      lastPage: (response.meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  Future<RedemptionQuote> quote(int id) async => RedemptionQuote.fromJson(
    (await _client.get('/transaksi/$id/poin')).asMap,
  );
  Future<RedemptionQuote> redeem(
    int id, {
    required int points,
    required int expectedTotal,
    required String requestId,
  }) async => RedemptionQuote.fromJson(
    (await _client.post(
      '/transaksi/$id/poin',
      body: {
        'points': points,
        'expected_grand_total': expectedTotal,
        'request_id': requestId,
      },
    )).asMap,
  );
}
