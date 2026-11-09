import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/transaksi_detail.dart';

class TimelineStatus extends StatelessWidget {
  const TimelineStatus({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return Text(
        'Belum ada riwayat status.',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          _TimelineTile(step: steps[index], isLast: index == steps.length - 1),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.step, required this.isLast});

  final TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDone = step.state == TimelineState.done;
    final isCurrent = step.state == TimelineState.current;
    final color = isDone || isCurrent
        ? colors.primary
        : colors.onSurfaceVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : isCurrent
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: color,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDone
                          ? colors.primary.withValues(alpha: 0.5)
                          : colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrent
                          ? FontWeight.w800
                          : isDone
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isCurrent
                          ? colors.primary
                          : isDone
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.at == null ? 'Menunggu' : formatTanggal(step.at!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
