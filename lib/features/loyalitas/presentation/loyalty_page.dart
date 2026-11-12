import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_artwork.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../application/loyalty_controller.dart';
import '../data/loyalty_repository.dart';

class LoyaltyPage extends ConsumerWidget {
  const LoyaltyPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Poin Sparkleen')),
        body: AsyncValueView<LoyaltyView>(
          value: ref.watch(loyaltySummaryProvider),
          onRetry: () => ref.invalidate(loyaltySummaryProvider),
          builder: (context, view) => RefreshIndicator(
            onRefresh: ref.read(loyaltySummaryProvider.notifier).refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          color: colors.primaryContainer,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  if (MediaQuery.textScalerOf(context)
                                          .scale(14) <
                                      20) ...[
                                    const AppArtwork(
                                      asset: AppAssets.points,
                                      width: 84,
                                      height: 84,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 76,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      color: colors.outlineVariant,
                                    ),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Saldo poinmu',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${view.summary.balance} poin',
                                          style: theme.textTheme.headlineLarge,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '1 poin = ${formatRupiah(view.summary.value)} potongan.',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: () => context.go('/pesanan'),
                                icon: const Icon(Icons.receipt_long_outlined),
                                label: const Text('Pilih pesanan'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tukar sebelum pembayaran pertama atau pembuatan tagihan.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 22),
                        Text('Riwayat poin', style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),
                if (view.summary.history.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: AppCard(
                        child: Text('Belum ada perubahan poin baru.'),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: view.summary.history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final item = view.summary.history[i];
                      return PointMovementTile(
                        item: item,
                        onTap: () => context.push('/pesanan/${item.orderId}'),
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (view.error != null)
                          Text(
                            view.error is ApiException
                                ? (view.error as ApiException).message
                                : 'Riwayat belum dapat dimuat.',
                            style: TextStyle(color: colors.error),
                          ),
                        if (view.busy)
                          const Center(child: CircularProgressIndicator()),
                        if (view.summary.page < view.summary.lastPage)
                          OutlinedButton(
                            onPressed: view.busy
                                ? null
                                : ref
                                      .read(loyaltySummaryProvider.notifier)
                                      .loadMore,
                            child: Text(
                              view.summary.page == 1
                                  ? 'Lihat semua riwayat poin'
                                  : 'Muat 20 berikutnya',
                            ),
                          ),
                        Text(
                          'Perubahan sejak fitur riwayat diaktifkan. Saldo sebelumnya tetap dipertahankan.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
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

class PointMovementTile extends StatelessWidget {
  const PointMovementTile({super.key, required this.item, required this.onTap});
  final PointMovement item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget detail() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.reason, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(item.nota, style: theme.textTheme.bodySmall),
        Text(
          'Saldo ${item.balanceAfter} poin',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
    Widget amount() => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${item.delta > 0 ? '+' : ''}${item.delta} poin',
          key: ValueKey('point-delta-${item.id}'),
          textAlign: TextAlign.right,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        if (item.createdAt != null)
          Text(
            formatTanggalSingkat(item.createdAt!),
            key: ValueKey('point-date-${item.id}'),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.textScalerOf(context).scale(14) > 20) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: detail()),
                  ],
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: amount()),
              ],
            );
          }
          return Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: theme.colorScheme.onSurface,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(child: detail()),
              const SizedBox(width: 10),
              amount(),
            ],
          );
        },
      ),
    );
  }
}
