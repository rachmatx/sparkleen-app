import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_artwork.dart';
import '../../../core/widgets/async_value_view.dart';
import '../application/pickup_controller.dart';
import '../data/pickup_repository.dart';

class PickupPage extends ConsumerStatefulWidget {
  const PickupPage({super.key});
  @override
  ConsumerState<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends ConsumerState<PickupPage> {
  final _cancelling = <int>{};
  Future<void> _cancel(PickupRequest item) async {
    final revision = ref.read(customerSessionRevisionProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan penjemputan?'),
        content: const Text(
          'Permintaan ini akan ditutup. Kamu bisa mengajukan jadwal baru setelahnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        revision != ref.read(customerSessionRevisionProvider)) {
      return;
    }
    setState(() => _cancelling.add(item.id));
    try {
      await ref.read(pickupControllerProvider.notifier).cancel(item.id);
    } catch (error) {
      if (mounted && revision == ref.read(customerSessionRevisionProvider)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Belum berhasil membatalkan. Coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(pickupControllerProvider);
    final active =
        requests.value?.result.items.any((item) => item.isActive) ?? false;
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Jemput laundry')),
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(pickupControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppArtwork(asset: AppAssets.home, height: 100),
                    const SizedBox(height: 12),
                    Text(
                      'Cucian dijemput dari rumah',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      active
                          ? 'Ada penjemputan yang sedang berjalan. Status terbaru akan tampil di bawah.'
                          : 'Pilih layanan, alamat, dan waktu. Outlet akan memproses permintaanmu.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: active
                          ? null
                          : () => context.push('/jemput/baru'),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        active
                            ? 'Permintaan sedang berjalan'
                            : 'Ajukan penjemputan',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Riwayat penjemputan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              AsyncValueView<PickupState>(
                value: requests,
                onRetry: () =>
                    ref.read(pickupControllerProvider.notifier).refresh(),
                isEmpty: (data) => data.result.items.isEmpty,
                emptyBuilder: (_) => const EmptyState(
                  message: 'Belum ada permintaan jemput. Mulai dari jadwal yang cocok untukmu.',
                  icon: Icons.local_shipping_outlined,
                  illustrationAsset: AppAssets.emptyActiveOrder,
                ),
                builder: (context, data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in data.result.items) ...[
                      _PickupCard(
                        item: item,
                        busy: _cancelling.contains(item.id),
                        onCancel: () => _cancel(item),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (data.error != null)
                      ErrorState(
                        error: data.error!,
                        onRetry: () => ref
                            .read(pickupControllerProvider.notifier)
                            .loadMore(),
                      ),
                    if (data.result.page < data.result.lastPage)
                      OutlinedButton(
                        onPressed: data.loadingMore
                            ? null
                            : () => ref
                                  .read(pickupControllerProvider.notifier)
                                  .loadMore(),
                        child: Text(
                          data.loadingMore
                              ? 'Memuat…'
                              : (data.result.page == 1
                                    ? 'Lihat semua riwayat'
                                    : 'Muat 20 berikutnya'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  const _PickupCard({
    required this.item,
    required this.busy,
    required this.onCancel,
  });
  final PickupRequest item;
  final bool busy;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                item.statusLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: item.status == 'ditolak'
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
              Text('#${item.id}', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 14),
          Text(item.service, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          // Schedule is a Jakarta calendar date, independent of the device time zone.
          Text(
            '${DateFormat('d MMM yyyy', 'id_ID').format(item.scheduledAt.toUtc().add(const Duration(hours: 7)))} · ${item.slotLabel}',
          ),
          const SizedBox(height: 8), Text(item.address),
          if (item.note?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(item.note!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          const TicketDivider(),
          const SizedBox(height: 12),
          Text(
            'Perkiraan ${item.estimatedWeight.toStringAsFixed(2).replaceAll('.', ',')} kg · ${formatRupiah(item.estimatedPrice)}',
            style: theme.textTheme.bodyMedium,
          ),
          if (item.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Text(
              'Alasan: ${item.rejectionReason}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (item.transactionId != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/pesanan/${item.transactionId}'),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Lihat pesanan & biaya akhir'),
            ),
          ],
          if (item.canCancel) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: busy ? null : onCancel,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(busy ? 'Membatalkan…' : 'Batalkan permintaan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
