class Pelanggan {
  const Pelanggan({
    required this.id,
    required this.kode,
    required this.nama,
    required this.noTelp,
    required this.alamat,
    required this.poin,
    required this.totalTransaksi,
  });

  final int id;
  final String kode;
  final String nama;
  final String noTelp;
  final String alamat;
  final int poin;
  final int totalTransaksi;

  factory Pelanggan.fromJson(Map<String, dynamic> json) {
    return Pelanggan(
      id: (json['id_pelanggan'] as num).toInt(),
      kode: json['kode_pelanggan'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      poin: (json['poin'] as num?)?.toInt() ?? 0,
      totalTransaksi: (json['total_transaksi'] as num?)?.toInt() ?? 0,
    );
  }
}
