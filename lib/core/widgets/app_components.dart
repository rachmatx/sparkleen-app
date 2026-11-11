import 'package:flutter/material.dart';

import 'app_card.dart';

class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      color: colors.primaryContainer,
      padding: const EdgeInsets.all(14),
      shadow: const [],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class AppSummaryRow extends StatelessWidget {
  const AppSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });
  final String label, value;
  final bool emphasized;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasized ? text.titleMedium : text.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (emphasized ? text.titleLarge : text.titleSmall)?.copyWith(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
