import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusBackground(status),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color statusColor(String status) {
  return switch (status) {
    'menunggu' => const Color(0xFFB45309),
    'proses' => const Color(0xFF0E7490),
    'setrika' => AppColors.primary,
    'selesai' => const Color(0xFF047857),
    'diambil' => AppColors.muted,
    _ => AppColors.muted,
  };
}

Color statusBackground(String status) {
  return switch (status) {
    'menunggu' => AppColors.warningSoft,
    'proses' => AppColors.aquaSoft,
    'setrika' => AppColors.primarySoft,
    'selesai' => AppColors.mintSoft,
    'diambil' => const Color(0xFFF1F2F7),
    _ => const Color(0xFFF1F2F7),
  };
}
