class OutletInfo {
  const OutletInfo({
    required this.nama,
    required this.noWa,
    required this.alamat,
    this.jamBuka = '',
    this.jamTutup = '',
  });

  final String nama;
  final String noWa;
  final String alamat;
  final String jamBuka;
  final String jamTutup;

  factory OutletInfo.fromJson(Map<String, dynamic> json) {
    return OutletInfo(
      nama: json['nama'] as String? ?? '',
      noWa: json['no_wa'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      jamBuka: json['jam_buka'] as String? ?? '',
      jamTutup: json['jam_tutup'] as String? ?? '',
    );
  }
}
