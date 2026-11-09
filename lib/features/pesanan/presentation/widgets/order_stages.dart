import 'package:flutter/material.dart';

/// These are process states, not a percentage or a time-based prediction.
class OrderStages extends StatelessWidget {
  const OrderStages({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final current = switch (status) {
      'menunggu' => 0,
      'proses' => 1,
      'setrika' => 2,
      'selesai' => 3,
      'diambil' => 4,
      _ => null,
    };
    if (current == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const labels = ['Diterima', 'Dicuci', 'Setrika', 'Siap'];
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 17;
    final children = [
      for (var index = 0; index < labels.length; index++)
        Semantics(
          label:
              '${labels[index]}, ${index < current
                  ? 'selesai'
                  : index == current
                  ? 'saat ini'
                  : 'menunggu'}',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: index == current
                      ? colors.primary
                      : index < current
                      ? (theme.brightness == Brightness.dark
                            ? const Color(0xFF7398C8)
                            : const Color(0xFF537FB9))
                      : (theme.brightness == Brightness.dark
                            ? const Color(0xFF71849B)
                            : const Color(0xFF8193A8)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                labels[index],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: index == current
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontWeight: index == current
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 8,
        runSpacing: 12,
        children: [
          for (final child in children)
            SizedBox(
              width:
                  (constraints.maxWidth - (largeText ? 8 : 24)) /
                  (largeText ? 2 : 4),
              child: child,
            ),
        ],
      ),
    );
  }
}
