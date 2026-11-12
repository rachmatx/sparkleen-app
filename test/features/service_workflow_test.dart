import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/features/pesanan/data/laundry_workflow.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_detail.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_ringkas.dart';

TransaksiDetail order(List<String> names, {String status = 'menunggu'}) =>
    TransaksiDetail.fromJson({
      'id_transaksi': 1,
      'no_nota': 'LAU/TEST/1',
      'tgl_masuk': '2026-11-12T08:00:00+07:00',
      'status': status,
      'status_label': status == 'setrika' ? 'Disetrika' : 'Diterima',
      'items': [
        for (var i = 0; i < names.length; i++) {'nama_layanan': names[i]},
      ],
      'timeline': [
        for (final entry in const {
          'menunggu': 'Diterima',
          'proses': 'Dicuci',
          'setrika': 'Disetrika',
          'selesai': 'Siap Diambil',
          'diambil': 'Selesai',
        }.entries)
          {
            'status': entry.key,
            'label': entry.value,
            'state': entry.key == status ? 'current' : 'pending',
            'at': entry.key == 'proses' ? '2026-11-12T09:00:00+07:00' : null,
          },
      ],
    });

void main() {
  test('summaries do not claim ironing without a matching service', () {
    TransaksiRingkas summary({String? service}) => TransaksiRingkas.fromJson({
      'id_transaksi': 1,
      'tgl_masuk': '2026-11-12',
      'status': 'setrika',
      'status_label': 'Disetrika',
      'nama_layanan': service,
    });
    expect(summary().customerStatusLabel, 'Diproses');
    expect(summary(service: 'Cuci Reguler').customerStatusLabel, 'Diproses');
    expect(summary(service: 'Cuci + Setrika').customerStatusLabel, 'Disetrika');
  });
  for (final service in [
    'Cuci Reguler',
    'Cuci Kering',
    'Cuci Kilat',
    ' Cuci   Reguler ',
  ]) {
    test('$service excludes ironing and preserves the original API data', () {
      final data = order([service]);
      expect(data.customerTimeline.map((s) => s.status), [
        'menunggu',
        'proses',
        'selesai',
        'diambil',
      ]);
      expect(data.timeline.any((s) => s.status == 'setrika'), true);
      expect(data.customerTimeline.first.state, TimelineState.current);
    });
  }
  for (final service in [
    'Cuci + Setrika',
    'Cuci & Setrika',
    'Cuci dan Setrika',
  ]) {
    test('$service keeps ironing and its actual current state', () {
      final data = order([service], status: 'setrika');
      expect(data.customerTimeline.map((s) => s.status), [
        'menunggu',
        'proses',
        'setrika',
        'selesai',
        'diambil',
      ]);
      expect(
        data.customerTimeline
            .singleWhere((s) => s.state == TimelineState.current)
            .status,
        'setrika',
      );
    });
  }
  test('ironing only and mixed orders use the union of selected services', () {
    expect(order(['Setrika Saja']).customerTimeline.map((s) => s.status), [
      'menunggu',
      'setrika',
      'selesai',
      'diambil',
    ]);
    expect(
      order(['Cuci Reguler', 'Setrika Saja']).customerTimeline
          .map((s) => s.status),
      ['menunggu', 'proses', 'setrika', 'selesai', 'diambil'],
    );
  });
  test('legacy unsupported current phase stays processing without inventing timestamps', () {
    final data = order(['Cuci Reguler'], status: 'setrika');
    final current = data.customerTimeline.singleWhere(
      (s) => s.state == TimelineState.current,
    );
    expect(current.status, 'proses');
    expect(current.label, 'Diproses');
    expect(data.customerStatusLabel, 'Diproses');
    expect(
      current.at,
      data.timeline.singleWhere((s) => s.status == 'proses').at,
    );
  });
  test('completed wash-only order ends at the real collected state', () {
    final data = order(['Cuci Reguler'], status: 'diambil');
    expect(data.customerTimeline.last.state, TimelineState.current);
    expect(
      data.customerTimeline.take(3).every((s) => s.state == TimelineState.done),
      true,
    );
  });
  test('unknown services do not silently discard the server workflow', () {
    final data = order(['Layanan Khusus']);
    expect(identical(data.customerTimeline, data.timeline), true);
    expect(
      LaundryWorkflow.fromNames(['Cuci Reguler', 'Layanan Khusus']).known,
      false,
    );
  });
  test('unknown services in summary use generic progress, without claiming ironing', () {
    expect(LaundryWorkflow.fromNames(const []).summaryStages, [
      'menunggu',
      'proses',
      'selesai',
    ]);
    final summary = TransaksiRingkas.fromJson({
      'id_transaksi': 1,
      'tgl_masuk': '2026-11-12',
      'nama_layanan': 'Cuci Reguler',
    });
    expect(summary.workflow.summaryStages, ['menunggu', 'proses', 'selesai']);
  });
}
