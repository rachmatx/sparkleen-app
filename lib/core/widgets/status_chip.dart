import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Status is communicated by readable text and its semantic color.
/// Kept under the existing name for the shared call sites.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, required this.label});
  final String status;
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: statusColor(status, brightness: Theme.of(context).brightness),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

Color statusColor(String status, {Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  return switch (status.trim().toLowerCase()) {
    'menunggu' ||
    'pending' ||
    'belum' ||
    'belum dibayar' => dark ? const Color(0xFFF3C56B) : AppColors.warning,
    'proses' ||
    'setrika' ||
    'processing' ||
    'diproses' ||
    'dikonfirmasi' ||
    'dijemput' => dark ? const Color(0xFF85BBFF) : AppColors.primary,
    'selesai' ||
    'lunas' ||
    'paid' ||
    'success' ||
    'diambil' ||
    'diterima' => dark ? const Color(0xFF79D5B3) : AppColors.success,
    'ditolak' ||
    'dibatalkan' ||
    'failed' ||
    'cancelled' ||
    'expired' => dark ? const Color(0xFFFFA6B8) : AppColors.danger,
    _ => dark ? const Color(0xFFA5B7CA) : AppColors.muted,
  };
}
