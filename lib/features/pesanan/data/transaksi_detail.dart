enum TimelineState { done, current, pending }

class TimelineStep {
  const TimelineStep({
    required this.status,
    required this.label,
    required this.state,
    this.at,
  });

  final String status;
  final String label;
  final TimelineState state;
  final DateTime? at;

  factory TimelineStep.fromJson(Map<String, dynamic> json) {
    final at = json['at'];
    return TimelineStep(
      status: json['status'] as String? ?? '',
      label: json['label'] as String? ?? '',
      state: switch (json['state']) {
        'done' => TimelineState.done,
        'current' => TimelineState.current,
        _ => TimelineState.pending,
      },
      at: at is String ? DateTime.tryParse(at) : null,
    );
  }
}

class TransaksiItem {
  const TransaksiItem({
    required this.idDetail,
    required this.idLayanan,
    required this.namaLayanan,
    required this.berat,
    required this.hargaSatuan,
    required this.subtotal,
  });

  final int idDetail;
  final int idLayanan;
  final String namaLayanan;
  final double berat;
  final int hargaSatuan;
  final int subtotal;

  factory TransaksiItem.fromJson(Map<String, dynamic> json) {
    return TransaksiItem(
      idDetail: (json['id_detail'] as num?)?.toInt() ?? 0,
      idLayanan: (json['id_layanan'] as num?)?.toInt() ?? 0,
      namaLayanan: json['nama_layanan'] as String? ?? '',
      berat: (json['berat'] as num?)?.toDouble() ?? 0,
      hargaSatuan: (json['harga_satuan'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class PembayaranItem {
  const PembayaranItem({
    required this.id,
    required this.nominalBayar,
    required this.metode,
    required this.status,
    this.tglBayar,
  });

  final int id;
  final DateTime? tglBayar;
  final int nominalBayar;
  final String metode;
  final String status;

  factory PembayaranItem.fromJson(Map<String, dynamic> json) {
    final tglBayar = json['tgl_bayar'];
    return PembayaranItem(
      id: (json['id_pembayaran'] as num?)?.toInt() ?? 0,
      tglBayar: tglBayar is String ? DateTime.tryParse(tglBayar) : null,
      nominalBayar: (json['nominal_bayar'] as num?)?.toInt() ?? 0,
      metode: json['metode'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class TransaksiDetail {
  const TransaksiDetail({
    required this.id,
    required this.noNota,
    required this.tglMasuk,
    required this.totalBerat,
    required this.totalBiaya,
    required this.diskon,
    required this.grandTotal,
    required this.status,
    required this.statusLabel,
    required this.statusPembayaran,
    required this.items,
    required this.pembayaran,
    required this.timeline,
    this.tglEstimasi,
    this.tglAktual,
    this.metodePembayaran,
    this.pinPengambilan,
  });

  final int id;
  final String noNota;
  final DateTime tglMasuk;
  final DateTime? tglEstimasi;
  final DateTime? tglAktual;
  final double totalBerat;
  final int totalBiaya;
  final int diskon;
  final int grandTotal;
  final String status;
  final String statusLabel;
  final String statusPembayaran;
  final String? metodePembayaran;
  final String? pinPengambilan;
  final List<TransaksiItem> items;
  final List<PembayaranItem> pembayaran;
  final List<TimelineStep> timeline;

  bool get sudahLunas => statusPembayaran == 'lunas';

  factory TransaksiDetail.fromJson(Map<String, dynamic> json) {
    final estimasi = json['tgl_selesai_estimasi'];
    final aktual = json['tgl_selesai_aktual'];
    return TransaksiDetail(
      id: (json['id_transaksi'] as num).toInt(),
      noNota: json['no_nota'] as String? ?? '',
      tglMasuk: DateTime.parse(json['tgl_masuk'] as String),
      tglEstimasi: estimasi is String ? DateTime.tryParse(estimasi) : null,
      tglAktual: aktual is String ? DateTime.tryParse(aktual) : null,
      totalBerat: (json['total_berat'] as num?)?.toDouble() ?? 0,
      totalBiaya: (json['total_biaya'] as num?)?.toInt() ?? 0,
      diskon: (json['diskon'] as num?)?.toInt() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      statusPembayaran: json['status_pembayaran'] as String? ?? '',
      metodePembayaran: json['metode_pembayaran'] as String?,
      pinPengambilan: json['pin_pengambilan'] as String?,
      items: _parseList(json['items'], TransaksiItem.fromJson),
      pembayaran: _parseList(json['pembayaran'], PembayaranItem.fromJson),
      timeline: _parseList(json['timeline'], TimelineStep.fromJson),
    );
  }
}

List<T> _parseList<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => parse(Map<String, dynamic>.from(item)))
      .toList();
}
