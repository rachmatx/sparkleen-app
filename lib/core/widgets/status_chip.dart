import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(status, brightness: theme.brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusBackground(status, brightness: theme.brightness),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color statusColor(String status, {Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  return switch (status) {
    'menunggu' => dark ? const Color(0xFFF3C56B) : AppColors.warning,
    'proses' || 'setrika' => dark ? const Color(0xFF85BBFF) : AppColors.primary,
    'selesai' => dark ? const Color(0xFF79D5B3) : AppColors.success,
    'diambil' => dark ? const Color(0xFFA5B7CA) : AppColors.muted,
    _ => dark ? const Color(0xFFA5B7CA) : AppColors.muted,
  };
}

Color statusBackground(
  String status, {
  Brightness brightness = Brightness.light,
}) {
  final dark = brightness == Brightness.dark;
  return switch (status) {
    'menunggu' => dark ? const Color(0xFF3D301A) : AppColors.warningSoft,
    'proses' ||
    'setrika' => dark ? const Color(0xFF173756) : AppColors.primarySoft,
    'selesai' => dark ? const Color(0xFF173C33) : AppColors.mintSoft,
    'diambil' => dark ? const Color(0xFF233B54) : AppColors.surfaceMuted,
    _ => dark ? const Color(0xFF233B54) : AppColors.surfaceMuted,
  };
}
