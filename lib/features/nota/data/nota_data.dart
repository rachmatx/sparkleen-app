import '../../home/data/outlet_info.dart';
import '../../pesanan/data/transaksi_detail.dart';

class NotaData {
  const NotaData({
    required this.outlet,
    required this.noNota,
    required this.tanggal,
    required this.items,
    required this.subtotal,
    required this.diskon,
    required this.grandTotal,
    required this.statusPembayaran,
    this.metode,
  });

  final OutletInfo outlet;
  final String noNota;
  final DateTime tanggal;
  final List<TransaksiItem> items;
  final int subtotal;
  final int diskon;
  final int grandTotal;
  final String? metode;
  final String statusPembayaran;

  factory NotaData.fromJson(Map<String, dynamic> json) {
    final outlet = json['outlet'];
    final items = json['items'];
    return NotaData(
      outlet: outlet is Map
          ? OutletInfo.fromJson(Map<String, dynamic>.from(outlet))
          : const OutletInfo(nama: '', noWa: '', alamat: ''),
      noNota: json['no_nota'] as String? ?? '',
      tanggal: DateTime.parse(json['tanggal'] as String),
      items: items is List
          ? items
                .whereType<Map>()
                .map(
                  (item) =>
                      TransaksiItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      diskon: (json['diskon'] as num?)?.toInt() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toInt() ?? 0,
      metode: json['metode'] as String?,
      statusPembayaran: json['status_pembayaran'] as String? ?? '',
    );
  }
}
