import 'package:sparkleen_mobile/features/nota/data/nota_data.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_detail.dart';

import 'home_fakes.dart';
import 'pesanan_fakes.dart';

FakeTransaksiRepository redesignTransaksiRepository() {
  final repository = FakeTransaksiRepository(
    results: {
      'aktif:1': [testTransaksiAktif],
    },
  );
  const items = [
    TransaksiItem(
      idDetail: 1,
      idLayanan: 1,
      namaLayanan: 'Cuci Kering',
      berat: 3.5,
      hargaSatuan: 7000,
      subtotal: 24500,
    ),
  ];
  repository.detailResults[87] = TransaksiDetail(
    id: 87,
    noNota: testTransaksiAktif.noNota,
    tglMasuk: testTransaksiAktif.tglMasuk,
    tglEstimasi: testTransaksiAktif.tglEstimasi,
    totalBerat: 3.5,
    totalBiaya: 24500,
    diskon: 0,
    grandTotal: 24500,
    status: 'proses',
    statusLabel: 'Dicuci',
    statusPembayaran: 'lunas',
    metodePembayaran: 'Tunai',
    pinPengambilan: '4821',
    items: items,
    pembayaran: const [],
    timeline: [
      TimelineStep(
        status: 'menunggu',
        label: 'Diterima',
        state: TimelineState.done,
        at: testTransaksiAktif.tglMasuk,
      ),
      TimelineStep(
        status: 'proses',
        label: 'Dicuci',
        state: TimelineState.current,
        at: testTransaksiAktif.tglMasuk.add(const Duration(hours: 1)),
      ),
      const TimelineStep(
        status: 'setrika',
        label: 'Disetrika',
        state: TimelineState.pending,
      ),
      const TimelineStep(
        status: 'selesai',
        label: 'Siap diambil',
        state: TimelineState.pending,
      ),
    ],
  );
  repository.notaResults[87] = NotaData(
    outlet: testOutlet,
    noNota: testTransaksiAktif.noNota,
    tanggal: testTransaksiAktif.tglMasuk,
    items: items,
    subtotal: 24500,
    diskon: 0,
    grandTotal: 24500,
    statusPembayaran: 'lunas',
    metode: 'Tunai',
  );
  return repository;
}
