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

class LoyaltyPage extends ConsumerWidget {
  const LoyaltyPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Poin Sparkleen')),
        body: AsyncValueView<LoyaltyView>(
          value: ref.watch(loyaltySummaryProvider),
          onRetry: () => ref.invalidate(loyaltySummaryProvider),
          builder: (context, view) => RefreshIndicator(
            onRefresh: ref.read(loyaltySummaryProvider.notifier).refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppArtwork(
                        asset: AppAssets.points,
                        width: 52,
                        height: 52,
                        fallbackIcon: Icons.stars_outlined,
                      ),
                      const SizedBox(height: 16),
                      const Text('Saldo poin Anda'),
                      const SizedBox(height: 6),
                      Text(
                        '${view.summary.balance} poin',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1 poin = ${formatRupiah(view.summary.value)} potongan laundry.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tukar melalui detail pesanan sebelum pembayaran pertama dan sebelum membuat tagihan online.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/pesanan'),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Pilih pesanan'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Riwayat poin',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Perubahan sejak fitur riwayat diaktifkan. Saldo sebelumnya tetap dipertahankan.',
                ),
                const SizedBox(height: 16),
                if (view.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      view.error is ApiException
                          ? (view.error as ApiException).message
                          : 'Riwayat belum dapat dimuat.',
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                if (view.summary.history.isEmpty)
                  const AppCard(child: Text('Belum ada perubahan poin baru.')),
                for (final item in view.summary.history)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => context.push('/pesanan/${item.orderId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              item.reason,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '${item.delta > 0 ? '+' : ''}${item.delta} poin',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item.nota),
                        const SizedBox(height: 6),
                        Text(
                          'Saldo setelah perubahan: ${item.balanceAfter} poin',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (item.createdAt != null)
                          Text(
                            formatTanggal(item.createdAt!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                if (view.busy) const Center(child: CircularProgressIndicator()),
                if (view.summary.page < view.summary.lastPage)
                  OutlinedButton(
                    onPressed: view.busy
                        ? null
                        : ref.read(loyaltySummaryProvider.notifier).loadMore,
                    child: const Text('Muat riwayat berikutnya'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
