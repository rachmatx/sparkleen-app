import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/features/auth/data/pelanggan.dart';
import 'package:sparkleen_mobile/features/home/data/layanan.dart';
import 'package:sparkleen_mobile/features/home/data/outlet_info.dart';
import 'package:sparkleen_mobile/features/nota/data/nota_data.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_detail.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_ringkas.dart';

void main() {
  group('Pelanggan', () {
    test('parsing profil lengkap', () {
      final pelanggan = Pelanggan.fromJson({
        'id_pelanggan': 12,
        'kode_pelanggan': 'PLG012',
        'nama': 'Budi Santoso',
        'no_telp': '6281298765432',
        'alamat': 'Jl. Merdeka No. 10',
        'poin': 15,
        'total_transaksi': 4,
      });

      expect(pelanggan.id, 12);
      expect(pelanggan.kode, 'PLG012');
      expect(pelanggan.nama, 'Budi Santoso');
      expect(pelanggan.noTelp, '6281298765432');
      expect(pelanggan.alamat, 'Jl. Merdeka No. 10');
      expect(pelanggan.poin, 15);
      expect(pelanggan.totalTransaksi, 4);
    });

    test('field opsional hilang memakai default', () {
      final pelanggan = Pelanggan.fromJson({
        'id_pelanggan': 12,
        'kode_pelanggan': 'PLG012',
        'nama': 'Budi',
        'no_telp': '62812',
        'alamat': 'Jl. Mawar',
      });

      expect(pelanggan.poin, 0);
      expect(pelanggan.totalTransaksi, 0);
    });
  });

  test('Layanan memakai harga integer rupiah', () {
    final layanan = Layanan.fromJson({
      'id_layanan': 1,
      'nama_layanan': 'Cuci Kering',
      'harga_per_kg': 7000,
      'estimasi_hari': 2,
    });

    expect(layanan.id, 1);
    expect(layanan.nama, 'Cuci Kering');
    expect(layanan.hargaPerKg, isA<int>());
    expect(layanan.hargaPerKg, 7000);
    expect(layanan.estimasiHari, 2);
  });

  test('OutletInfo parsing lengkap dan tanpa jam operasional', () {
    final outlet = OutletInfo.fromJson({
      'nama': 'Sparkleen Laundry',
      'no_wa': '6281234567890',
      'alamat': 'Jl. Contoh No. 1',
      'jam_buka': '08:00',
      'jam_tutup': '21:00',
    });
    final outletNota = OutletInfo.fromJson({
      'nama': 'Sparkleen Laundry',
      'no_wa': '6281234567890',
      'alamat': 'Jl. Contoh No. 1',
    });

    expect(outlet.nama, 'Sparkleen Laundry');
    expect(outlet.noWa, '6281234567890');
    expect(outlet.jamBuka, '08:00');
    expect(outlet.jamTutup, '21:00');
    expect(outletNota.jamBuka, isEmpty);
    expect(outletNota.jamTutup, isEmpty);
  });

  group('TransaksiRingkas', () {
    test('parsing item riwayat', () {
      final transaksi = TransaksiRingkas.fromJson({
        'id_transaksi': 87,
        'no_nota': 'LAU/20261021/0001',
        'tgl_masuk': '2026-10-21T09:00:00+07:00',
        'tgl_selesai_estimasi': '2026-10-23T09:00:00+07:00',
        'total_berat': 3.5,
        'grand_total': 24500,
        'status': 'proses',
        'status_label': 'Dicuci',
      });

      expect(transaksi.id, 87);
      expect(transaksi.noNota, 'LAU/20261021/0001');
      expect(transaksi.tglMasuk.toUtc(), DateTime.utc(2026, 10, 21, 2));
      expect(transaksi.tglEstimasi?.toUtc(), DateTime.utc(2026, 10, 23, 2));
      expect(transaksi.totalBerat, 3.5);
      expect(transaksi.grandTotal, isA<int>());
      expect(transaksi.grandTotal, 24500);
      expect(transaksi.status, 'proses');
      expect(transaksi.statusLabel, 'Dicuci');
      expect(transaksi.isAktif, isTrue);
    });

    test('status selesai tidak dianggap aktif', () {
      final transaksi = TransaksiRingkas.fromJson({
        'id_transaksi': 1,
        'no_nota': 'LAU/20261021/0002',
        'tgl_masuk': '2026-10-21T09:00:00+07:00',
        'grand_total': 0,
        'status': 'diambil',
        'status_label': 'Selesai',
      });

      expect(transaksi.isAktif, isFalse);
      expect(transaksi.tglEstimasi, isNull);
    });
  });

  group('TransaksiDetail', () {
    final json = {
      'id_transaksi': 87,
      'no_nota': 'LAU/20261021/0001',
      'tgl_masuk': '2026-10-21T09:00:00+07:00',
      'tgl_selesai_estimasi': '2026-10-23T09:00:00+07:00',
      'tgl_selesai_aktual': null,
      'total_berat': 3.5,
      'total_biaya': 24500,
      'diskon': 0,
      'grand_total': 24500,
      'status': 'proses',
      'status_label': 'Dicuci',
      'status_pembayaran': 'belum',
      'metode_pembayaran': null,
      'pin_pengambilan': '4821',
      'items': [
        {
          'id_detail': 1,
          'id_layanan': 1,
          'nama_layanan': 'Cuci Kering',
          'berat': 3.5,
          'harga_satuan': 7000,
          'subtotal': 24500,
        },
      ],
      'pembayaran': [
        {
          'id_pembayaran': 1,
          'tgl_bayar': '2026-10-21T09:15:00+07:00',
          'nominal_bayar': 24500,
          'metode': 'cash',
          'status': 'lunas',
        },
      ],
      'timeline': [
        {
          'status': 'menunggu',
          'label': 'Diterima',
          'at': '2026-10-21T09:00:00+07:00',
          'state': 'done',
        },
        {
          'status': 'proses',
          'label': 'Dicuci',
          'at': '2026-10-21T13:00:00+07:00',
          'state': 'current',
        },
        {
          'status': 'setrika',
          'label': 'Disetrika',
          'at': null,
          'state': 'pending',
        },
        {
          'status': 'selesai',
          'label': 'Siap Diambil',
          'at': null,
          'state': 'pending',
        },
        {
          'status': 'diambil',
          'label': 'Selesai',
          'at': null,
          'state': 'pending',
        },
      ],
    };

    test('parsing detail beserta item, pembayaran, dan timeline', () {
      final detail = TransaksiDetail.fromJson(json);

      expect(detail.id, 87);
      expect(detail.noNota, 'LAU/20261021/0001');
      expect(detail.tglMasuk.toUtc(), DateTime.utc(2026, 10, 21, 2));
      expect(detail.tglAktual, isNull);
      expect(detail.totalBiaya, 24500);
      expect(detail.diskon, 0);
      expect(detail.grandTotal, 24500);
      expect(detail.statusPembayaran, 'belum');
      expect(detail.sudahLunas, isFalse);
      expect(detail.metodePembayaran, isNull);
      expect(detail.pinPengambilan, '4821');

      expect(detail.items, hasLength(1));
      expect(detail.items.first.namaLayanan, 'Cuci Kering');
      expect(detail.items.first.berat, 3.5);
      expect(detail.items.first.subtotal, 24500);

      expect(detail.pembayaran, hasLength(1));
      expect(detail.pembayaran.first.nominalBayar, 24500);
      expect(detail.pembayaran.first.metode, 'cash');
      expect(detail.pembayaran.first.status, 'lunas');

      expect(detail.timeline, hasLength(5));
      expect(detail.timeline[0].state, TimelineState.done);
      expect(detail.timeline[1].state, TimelineState.current);
      expect(detail.timeline[2].state, TimelineState.pending);
      expect(detail.timeline[2].at, isNull);
      expect(detail.timeline[1].at?.toUtc(), DateTime.utc(2026, 10, 21, 6));
    });

    test('list opsional hilang menjadi kosong dan state tak dikenal pending', () {
      final detail = TransaksiDetail.fromJson({
        'id_transaksi': 88,
        'no_nota': 'LAU/20261021/0003',
        'tgl_masuk': '2026-10-21T09:00:00+07:00',
        'grand_total': 0,
        'timeline': [
          {'status': 'proses', 'label': 'Dicuci', 'state': 'aneh'},
        ],
      });

      expect(detail.items, isEmpty);
      expect(detail.pembayaran, isEmpty);
      expect(detail.timeline, hasLength(1));
      expect(detail.timeline.first.state, TimelineState.pending);
      expect(detail.pinPengambilan, isNull);
    });
  });

  test('NotaData parsing tanpa PIN pengambilan', () {
    final nota = NotaData.fromJson({
      'outlet': {
        'nama': 'Sparkleen Laundry',
        'no_wa': '6281234567890',
        'alamat': 'Jl. Contoh No. 1',
      },
      'no_nota': 'LAU/20261021/0001',
      'tanggal': '2026-10-21T09:00:00+07:00',
      'items': [
        {
          'id_detail': 1,
          'id_layanan': 1,
          'nama_layanan': 'Cuci Kering',
          'berat': 3.5,
          'harga_satuan': 7000,
          'subtotal': 24500,
        },
      ],
      'subtotal': 24500,
      'diskon': 0,
      'grand_total': 24500,
      'metode': 'cash',
      'status_pembayaran': 'belum',
      'pin_pengambilan': '4821',
    });

    expect(nota.outlet.nama, 'Sparkleen Laundry');
    expect(nota.noNota, 'LAU/20261021/0001');
    expect(nota.tanggal.toUtc(), DateTime.utc(2026, 10, 21, 2));
    expect(nota.items, hasLength(1));
    expect(nota.subtotal, 24500);
    expect(nota.grandTotal, 24500);
    expect(nota.metode, 'cash');
    expect(nota.statusPembayaran, 'belum');
  });
}
