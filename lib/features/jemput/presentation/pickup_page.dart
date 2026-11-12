import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/status_chip.dart';
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
    final theme = Theme.of(context);
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Jemput laundry')),
        body: AsyncValueView<PickupState>(
          value: ref.watch(pickupControllerProvider),
          onRetry: () => ref.read(pickupControllerProvider.notifier).refresh(),
          builder: (context, data) {
            final active = data.result.items
                .where((item) => item.isActive)
                .toList();
            final history = data.result.items
                .where((item) => !item.isActive)
                .toList();
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(pickupControllerProvider.notifier).refresh(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppCard(
                            color: theme.colorScheme.primaryContainer,
                            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Cucian dijemput,\nkamu tetap santai.',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ),
                                if (MediaQuery.textScalerOf(context).scale(14) <
                                    20)
                                  const AppArtwork(
                                    asset: AppAssets.pickup,
                                    width: 140,
                                    height: 100,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (active.isNotEmpty)
                            AppInfoBanner(
                              message: '${active.length} permintaan aktif',
                            )
                          else
                            FilledButton.icon(
                              onPressed: () => context.push('/jemput/baru'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Ajukan penjemputan'),
                            ),
                          const SizedBox(height: 18),
                          if (active.isNotEmpty)
                            Text(
                              'Penjemputan aktif',
                              style: theme.textTheme.titleLarge,
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: active.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _PickupCard(
                        item: active[i],
                        busy: _cancelling.contains(active[i].id),
                        onCancel: () => _cancel(active[i]),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Riwayat penjemputan',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                  if (history.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: AppCard(
                          child: Text('Belum ada riwayat penjemputan.'),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _PickupCard(
                        item: history[i],
                        busy: false,
                        onCancel: () {},
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (data.error != null)
                            Text(
                              data.error is ApiException
                                  ? (data.error as ApiException).message
                                  : 'Riwayat belum dapat dimuat.',
                              style: TextStyle(color: theme.colorScheme.error),
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
                                    : data.result.page == 1
                                    ? 'Lihat semua riwayat'
                                    : 'Muat 20 berikutnya',
                              ),
                            ),
                          if (active.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: .07,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Permintaan sedang berjalan',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ajukan lagi setelah permintaan selesai.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    if (!item.isActive) {
      return AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rincian penjemputan #${item.id}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(item.service, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  line(
                    Icons.calendar_today_outlined,
                    '${formatTanggalSingkat(item.scheduledAt)} · ${item.slotLabel}',
                  ),
                  line(Icons.location_on_outlined, item.address),
                  line(
                    Icons.shopping_basket_outlined,
                    'Perkiraan ${formatBerat(item.estimatedWeight)} · ${formatRupiah(item.estimatedPrice)}',
                  ),
                  if (item.note?.isNotEmpty == true) Text(item.note!),
                  if (item.rejectionReason != null)
                    Text(
                      'Alasan: ${item.rejectionReason}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                StatusChip(status: item.status, label: item.statusLabel),
                Text('#${item.id}', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.service, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 3),
                      Text(
                        formatTanggalSingkat(item.scheduledAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (item.transactionId != null)
                  Flexible(
                    child: TextButton.icon(
                      onPressed: () =>
                          context.push('/pesanan/${item.transactionId}'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: const Text('Lihat pesanan'),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusChip(status: item.status, label: item.statusLabel),
              Text('#${item.id}', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.service, style: theme.textTheme.titleSmall),
          if (item.isActive) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            line(
              Icons.calendar_today_outlined,
              '${formatTanggalSingkat(item.scheduledAt)} · ${item.slotLabel}',
            ),
            line(Icons.location_on_outlined, item.address),
            line(
              Icons.shopping_basket_outlined,
              'Perkiraan ${formatBerat(item.estimatedWeight)}',
            ),
            if (item.note?.isNotEmpty == true)
              line(Icons.notes_rounded, item.note!),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            AppSummaryRow(
              label: 'Perkiraan biaya',
              value: formatRupiah(item.estimatedPrice),
              emphasized: true,
            ),
            Text(
              'Jadwal akan dikonfirmasi outlet.',
              style: theme.textTheme.bodySmall,
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              formatTanggalSingkat(item.scheduledAt),
              style: theme.textTheme.bodySmall,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                'Rincian penjemputan',
                style: theme.textTheme.bodySmall,
              ),
              children: [
                line(Icons.location_on_outlined, item.address),
                line(
                  Icons.shopping_basket_outlined,
                  '${formatBerat(item.estimatedWeight)} · ${formatRupiah(item.estimatedPrice)}',
                ),
                if (item.note?.isNotEmpty == true)
                  Text(item.note!, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
          if (item.rejectionReason != null)
            Text(
              'Alasan: ${item.rejectionReason}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (item.transactionId != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/pesanan/${item.transactionId}'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Lihat pesanan & biaya akhir'),
              ),
            ),
          if (item.canCancel)
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
      ),
    );
  }
}
