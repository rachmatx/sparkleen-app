import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/features/home/data/outlet_info.dart';
import 'package:sparkleen_mobile/features/nota/data/nota_data.dart';
import 'package:sparkleen_mobile/features/nota/presentation/nota_page.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_detail.dart';

import '../support/pesanan_fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('nota menampilkan nomor, total, dan tanpa PIN pengambilan', (
    tester,
  ) async {
    final repository = FakeTransaksiRepository()
      ..notaResults[87] = NotaData(
        outlet: const OutletInfo(
          nama: 'Sparkleen Laundry',
          noWa: '6281234567890',
          alamat: 'Jl. Contoh No. 1',
        ),
        noNota: 'LAU/20261021/0001',
        tanggal: DateTime.parse('2026-10-21T09:00:00+07:00'),
        items: const [
          TransaksiItem(
            idDetail: 1,
            idLayanan: 1,
            namaLayanan: 'Cuci Kering',
            berat: 3.5,
            hargaSatuan: 7000,
            subtotal: 24500,
          ),
        ],
        subtotal: 24500,
        diskon: 0,
        grandTotal: 24500,
        metode: 'cash',
        statusPembayaran: 'lunas',
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transaksiRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: NotaPage(id: 87)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repository.notaCalls, [87]);
    expect(find.text('LAU/20261021/0001'), findsOneWidget);
    expect(find.text('Rp 24.500'), findsWidgets);
    expect(find.text('Cuci Kering'), findsOneWidget);
    expect(find.text('Terima kasih'), findsOneWidget);
    expect(find.text('4821'), findsNothing);
  });
}
