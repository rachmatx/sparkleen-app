import 'laundry_workflow.dart';

class TransaksiRingkas {
  const TransaksiRingkas({
    required this.id,
    required this.noNota,
    required this.tglMasuk,
    required this.totalBerat,
    required this.grandTotal,
    required this.status,
    required this.statusLabel,
    this.tglEstimasi,
    this.serviceNames = const [],
  });

  final List<String> serviceNames;
  LaundryWorkflow get workflow => LaundryWorkflow.fromNames(serviceNames);
  final int id;
  final String noNota;
  final DateTime tglMasuk;
  final DateTime? tglEstimasi;
  final double totalBerat;
  final int grandTotal;
  final String status;
  final String statusLabel;

  bool get isAktif =>
      status == 'menunggu' || status == 'proses' || status == 'setrika';

  factory TransaksiRingkas.fromJson(Map<String, dynamic> json) {
    final estimasi = json['tgl_selesai_estimasi'];
    return TransaksiRingkas(
      id: (json['id_transaksi'] as num).toInt(),
      noNota: json['no_nota'] as String? ?? '',
      tglMasuk: DateTime.parse(json['tgl_masuk'] as String),
      tglEstimasi: estimasi is String ? DateTime.tryParse(estimasi) : null,
      totalBerat: (json['total_berat'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      serviceNames: json['nama_layanan'] is String
          ? [json['nama_layanan'] as String]
          : json['items'] is List
          ? (json['items'] as List)
                .whereType<Map>()
                .map((item) => item['nama_layanan'])
                .whereType<String>()
                .toList()
          : const [],
    );
  }
}
