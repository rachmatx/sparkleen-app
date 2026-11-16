class Layanan {
  const Layanan({
    required this.id,
    required this.nama,
    required this.hargaPerKg,
    required this.estimasiHari,
    this.assetKey,
  });

  final int id;
  final String nama;
  final int hargaPerKg;
  final int estimasiHari;
  final String? assetKey;

  factory Layanan.fromJson(Map<String, dynamic> json) {
    return Layanan(
      id: (json['id_layanan'] as num).toInt(),
      nama: json['nama_layanan'] as String? ?? '',
      hargaPerKg: (json['harga_per_kg'] as num?)?.toInt() ?? 0,
      estimasiHari: (json['estimasi_hari'] as num?)?.toInt() ?? 0,
      assetKey: json['asset_key'] is String
          ? json['asset_key'] as String
          : null,
    );
  }
}
