import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../application/notification_controller.dart';
import '../data/notification_repository.dart';

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});
  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  void _refresh() {
    if (mounted &&
        _foreground &&
        !ref.read(unreadNotificationsProvider).isLoading) {
      ref.invalidate(unreadNotificationsProvider);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(unreadNotificationsProvider);
    final unread = summary.isLoading ? 0 : (summary.value ?? 0);
    return IconButton(
      tooltip: unread > 0 ? 'Notifikasi, $unread belum dibaca' : 'Notifikasi',
      onPressed: () async {
        await context.push('/notifikasi');
        if (mounted) ref.invalidate(unreadNotificationsProvider);
      },
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    CustomerNotification item,
  ) async {
    if (item.unread &&
        !await ref.read(notificationsProvider.notifier).mark(id: item.id)) {
      return;
    }
    if (!context.mounted) return;
    switch (item.targetType) {
      case 'order':
        if (item.targetId != null && item.targetId! > 0) {
          await context.push('/pesanan/${item.targetId}');
        }
      case 'pickup':
        await context.push('/jemput');
      case 'loyalty':
        await context.push('/poin');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(notificationsProvider);
    final controller = ref.read(notificationsProvider.notifier);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Notifikasi')),
        body: AsyncValueView<NotificationView>(
          value: value,
          onRetry: () => ref.invalidate(notificationsProvider),
          builder: (context, view) => RefreshIndicator(
            onRefresh: controller.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kabar terbaru cucianmu.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final section = Text(
                              'Hari ini',
                              style: theme.textTheme.titleMedium,
                            );
                            final action = TextButton.icon(
                              style: TextButton.styleFrom(
                                textStyle: theme.textTheme.bodySmall,
                              ),
                              onPressed: view.busy || view.result.unread == 0
                                  ? null
                                  : () => controller.mark(),
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Tandai semua dibaca'),
                            );
                            if (MediaQuery.textScalerOf(context).scale(14) >
                                20) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  section,
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: action,
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                section,
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: action,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (view.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              view.error is ApiException
                                  ? (view.error as ApiException).message
                                  : 'Pembaruan belum tersimpan. Coba lagi.',
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                        if (view.result.items.isEmpty)
                          const EmptyState(
                            icon: Icons.notifications_none_rounded,
                            message: 'Belum ada notifikasi',
                          ),
                        if (view.result.items.isNotEmpty &&
                            !view.result.items.any(
                              (item) => _isToday(item.createdAt),
                            ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Belum ada notifikasi hari ini.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList.separated(
                    itemCount: view.result.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = view.result.items[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isToday(item.createdAt) &&
                              (index == 0 ||
                                  _isToday(
                                    view.result.items[index - 1].createdAt,
                                  )))
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 12,
                              ),
                              child: Text(
                                'Sebelumnya',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          AppCard(
                            color: item.unread ? colors.primaryContainer : null,
                            padding: const EdgeInsets.all(16),
                            onTap: view.busy
                                ? null
                                : () => _open(context, ref, item),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  switch (item.category) {
                                    'payment' => Icons.payments_outlined,
                                    'pickup' => Icons.local_shipping_outlined,
                                    'loyalty' => Icons.stars_outlined,
                                    _ => Icons.local_laundry_service_outlined,
                                  },
                                  color: colors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: item.unread
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          if (item.unread) ...[
                                            const SizedBox(width: 10),
                                            Semantics(
                                              label: 'Belum dibaca',
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 5,
                                                ),
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: colors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.body,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      if (item.createdAt != null) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          formatTanggal(item.createdAt!),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (view.busy)
                          const Center(child: CircularProgressIndicator()),
                        if (view.result.page < view.result.lastPage)
                          OutlinedButton(
                            onPressed: view.busy ? null : controller.loadMore,
                            child: Text(
                              view.result.page == 1
                                  ? 'Lihat semua notifikasi'
                                  : 'Muat 20 berikutnya',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isToday(DateTime? date) {
  if (date == null) return false;
  final local = date.toUtc().add(const Duration(hours: 7));
  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}
