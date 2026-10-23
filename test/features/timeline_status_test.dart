import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_detail.dart';
import 'package:sparkleen_mobile/features/pesanan/presentation/widgets/timeline_status.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('timeline merender state done, current, dan pending', (
    tester,
  ) async {
    final steps = [
      TimelineStep(
        status: 'menunggu',
        label: 'Diterima',
        state: TimelineState.done,
        at: DateTime.parse('2026-10-21T09:00:00+07:00'),
      ),
      TimelineStep(
        status: 'proses',
        label: 'Dicuci',
        state: TimelineState.current,
        at: DateTime.parse('2026-10-21T13:00:00+07:00'),
      ),
      const TimelineStep(
        status: 'setrika',
        label: 'Disetrika',
        state: TimelineState.pending,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: TimelineStatus(steps: steps)),
        ),
      ),
    );

    expect(find.text('Diterima'), findsOneWidget);
    expect(find.text('Dicuci'), findsOneWidget);
    expect(find.text('Disetrika'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
  });

  testWidgets('timeline kosong menampilkan pesan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TimelineStatus(steps: [])),
      ),
    );

    expect(find.text('Belum ada riwayat status.'), findsOneWidget);
  });
}
