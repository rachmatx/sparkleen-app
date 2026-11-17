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

String formatEstimasi(DateTime value) =>
    DateFormat('d MMMM · HH.mm', 'id_ID').format(value.toLocal());

/// Calendar fields in the outlet's timezone, independent of the phone timezone.
DateTime jakartaCalendarDate({DateTime? instant, int daysAfter = 0}) {
  final local = (instant ?? DateTime.now()).toUtc().add(
    const Duration(hours: 7),
  );
  return DateTime(local.year, local.month, local.day + daysAfter);
}

/// Format Indonesian numbers for display without changing API payloads.
String formatTelepon(String value) {
  var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
  if (!digits.startsWith('62') || digits.length < 10 || digits.length > 15) {
    return value;
  }
  final national = digits.substring(2);
  final groups = <String>[national.substring(0, 3)];
  for (var index = 3; index < national.length; index += 4) {
    groups.add(
      national.substring(index, (index + 4).clamp(0, national.length)),
    );
  }
  return '+62 ${groups.join('-')}';
}
