import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/features/home/data/home_repository.dart';
import 'package:sparkleen_mobile/features/home/data/layanan.dart';
import 'package:sparkleen_mobile/features/home/data/outlet_info.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_ringkas.dart';

const testOutlet = OutletInfo(
  nama: 'Sparkleen Laundry',
  noWa: '6281234567890',
  alamat: 'Jl. Contoh No. 1',
  jamBuka: '08:00',
  jamTutup: '21:00',
);

final testLayanan = [
  const Layanan(
    id: 1,
    nama: 'Cuci Kering',
    hargaPerKg: 7000,
    estimasiHari: 2,
  ),
];

final testTransaksiAktif = TransaksiRingkas(
  id: 87,
  noNota: 'LAU/20261021/0001',
  tglMasuk: DateTime.parse('2026-10-21T09:00:00+07:00'),
  tglEstimasi: DateTime.parse('2026-10-23T09:00:00+07:00'),
  totalBerat: 3.5,
  grandTotal: 24500,
  status: 'proses',
  statusLabel: 'Dicuci',
);

class FakeHomeRepository implements HomeRepository {
  List<Layanan> layananResult = const [];
  OutletInfo outletResult = testOutlet;
  TransaksiRingkas? pesananAktifResult;

  ApiException? layananError;
  ApiException? outletError;
  ApiException? pesananError;

  @override
  Future<List<Layanan>> layanan() async {
    final error = layananError;
    if (error != null) throw error;
    return layananResult;
  }

  @override
  Future<OutletInfo> outlet() async {
    final error = outletError;
    if (error != null) throw error;
    return outletResult;
  }

  @override
  Future<TransaksiRingkas?> pesananAktif() async {
    final error = pesananError;
    if (error != null) throw error;
    return pesananAktifResult;
  }
}
