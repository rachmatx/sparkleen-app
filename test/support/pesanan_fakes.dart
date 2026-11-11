import 'package:sparkleen_mobile/features/nota/data/nota_data.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_detail.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_repository.dart';
import 'package:sparkleen_mobile/features/pesanan/data/transaksi_ringkas.dart';

TransaksiRingkas testTransaksi(
  int id, {
  String status = 'proses',
  String label = 'Dicuci',
}) {
  return TransaksiRingkas(
    id: id,
    noNota: 'LAU/20261021/${id.toString().padLeft(4, '0')}',
    tglMasuk: DateTime.parse('2026-10-21T09:00:00+07:00'),
    tglEstimasi: DateTime.parse('2026-10-23T09:00:00+07:00'),
    totalBerat: 3.5,
    grandTotal: 24500,
    status: status,
    statusLabel: label,
  );
}

class FakeTransaksiRepository implements TransaksiRepository {
  FakeTransaksiRepository({
    Map<String, List<TransaksiRingkas>>? results,
    this.lastPage = 1,
    this.error,
  }) : results = results ?? const {};

  /// Key berformat `<status>:<page>`.
  final Map<String, List<TransaksiRingkas>> results;
  final int lastPage;
  Object? error;
  Object? detailError;
  Object? notaError;
  final Map<int, TransaksiDetail> detailResults = {};
  final Map<int, NotaData> notaResults = {};
  final List<({String status, int page})> calls = [];
  final List<int> detailCalls = [];
  final List<int> perPageCalls = [];
  final List<int> notaCalls = [];

  @override
  Future<TransaksiListResult> list({
    required String status,
    int page = 1,
    int perPage = 20,
  }) async {
    calls.add((status: status, page: page));
    perPageCalls.add(perPage);
    final failure = error;
    if (failure != null) throw failure;

    final items = results['$status:$page'] ?? const [];
    return TransaksiListResult(
      items: items,
      page: page,
      lastPage: lastPage,
      total: items.length,
    );
  }

  @override
  Future<TransaksiDetail> detail(int id) async {
    detailCalls.add(id);
    final failure = detailError;
    if (failure != null) throw failure;
    final detail = detailResults[id];
    if (detail == null) {
      throw StateError('Detail transaksi $id belum disiapkan di fake.');
    }
    return detail;
  }

  @override
  Future<NotaData> nota(int id) async {
    notaCalls.add(id);
    final failure = notaError;
    if (failure != null) throw failure;
    final nota = notaResults[id];
    if (nota == null) {
      throw StateError('Nota transaksi $id belum disiapkan di fake.');
    }
    return nota;
  }
}
