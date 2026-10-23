import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
final _tanggalLengkap = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
final _tanggalSingkat = DateFormat('d MMM yyyy', 'id_ID');

String formatRupiah(int value) => _rupiah.format(value);

String formatTanggal(DateTime value) => _tanggalLengkap.format(value.toLocal());

String formatTanggalSingkat(DateTime value) =>
    _tanggalSingkat.format(value.toLocal());

String formatBerat(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return '$text kg';
}
