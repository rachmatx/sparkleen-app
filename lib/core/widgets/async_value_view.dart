import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import 'app_card.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyBuilder,
    this.onRetry,
    this.loadingBuilder,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final WidgetBuilder? emptyBuilder;
  final VoidCallback? onRetry;
  final WidgetBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => loadingBuilder?.call(context) ?? const LoadingList(),
      error: (error, stackTrace) => ErrorState(error: error, onRetry: onRetry),
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          return emptyBuilder?.call(context) ?? const EmptyState();
        }
        return builder(context, data);
      },
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({super.key, this.itemCount = 3, this.itemHeight = 84});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
              semanticsLabel: 'Memuat data',
            ),
          ),
        ),
        ...List.generate(itemCount, (index) {
          return ExcludeSemantics(
            child: AppCard(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 10),
              color: colors.surfaceContainerHigh,
              shadow: const [],
              child: SizedBox(width: double.infinity, height: itemHeight),
            ),
          );
        }),
      ],
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final message = error is ApiException
        ? (error as ApiException).message
        : 'Terjadi kesalahan. Silakan coba lagi.';

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 22,
                color: colors.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.message = 'Belum ada data.',
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
