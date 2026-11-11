import '../../../core/theme/app_assets.dart';
import '../../../core/widgets/app_artwork.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../application/pesanan_controller.dart';
import '../data/transaksi_detail.dart';
import 'widgets/timeline_status.dart';

final transaksiDetailProvider = FutureProvider.autoDispose
    .family<TransaksiDetail, int>((ref, id) {
      ref.watch(customerSessionRevisionProvider);
      return ref.watch(transaksiRepositoryProvider).detail(id);
    });

class DetailPesananPage extends ConsumerWidget {
  const DetailPesananPage({super.key, required this.id});

  final int id;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(transaksiDetailProvider(id));
    try {
      await ref.read(transaksiDetailProvider(id).future);
    } on Object {
      // Error sudah ditampilkan oleh AsyncValueView.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transaksiDetailProvider(id));

    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Detail pesanan')),
        body: AsyncValueView<TransaksiDetail>(
          value: async,
          onRetry: () => ref.invalidate(transaksiDetailProvider(id)),
          loadingBuilder: (context) => const Padding(
            padding: EdgeInsets.all(20),
            child: LoadingList(itemCount: 3, itemHeight: 120),
          ),
          builder: (context, detail) => RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _HeaderCard(detail: detail),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Perjalanan cucian',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 20),
                  child: TimelineStatus(
                    steps: detail.timeline
                        .where(
                          (step) =>
                              step.status != 'diambil' ||
                              step.state != TimelineState.pending,
                        )
                        .toList(),
                  ),
                ),
                _ItemsCard(items: detail.items),
                _PaymentCard(detail: detail),
                const SizedBox(height: 16),
                _PinCard(pin: detail.pinPengambilan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.detail});
  final TransaksiDetail detail;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 18),
      color: theme.colorScheme.primaryContainer,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (MediaQuery.textScalerOf(context).scale(14) < 20) ...[
            const AppArtwork(asset: AppAssets.home, width: 94, height: 92),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      detail.noNota,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    StatusChip(
                      status: detail.status,
                      label: detail.statusLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text('Estimasi selesai', style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  detail.tglEstimasi == null
                      ? 'Menunggu estimasi'
                      : formatEstimasi(detail.tglEstimasi!),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  formatBerat(detail.totalBerat),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items});

  final List<TransaksiItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'Rincian Layanan',
      child: items.isEmpty
          ? Text('Belum ada rincian layanan.', style: theme.textTheme.bodySmall)
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0)
                    Divider(
                      height: 28,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  _ItemRow(item: items[index]),
                ],
              ],
            ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final TransaksiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppArtwork(
          asset:
              AppAssets.serviceArtwork(name: item.namaLayanan) ??
              AppAssets.home,
          width: 48,
          height: 48,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.namaLayanan,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatBerat(item.berat)} × ${formatRupiah(item.hargaSatuan)}/kg',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            formatRupiah(item.subtotal),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends ConsumerWidget {
  const _PaymentCard({required this.detail});
  final TransaksiDetail detail;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Future<void> open(String route) async {
      await context.push(route);
      if (context.mounted) ref.invalidate(transaksiDetailProvider(detail.id));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total tagihan', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(detail.grandTotal),
                    style: theme.textTheme.headlineSmall,
                  ),
                  if (detail.diskon > 0)
                    Text(
                      'Diskon ${formatRupiah(detail.diskon)}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              StatusChip(
                status: detail.sudahLunas ? 'selesai' : 'menunggu',
                label: detail.sudahLunas ? 'Lunas' : 'Belum dibayar',
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!detail.sudahLunas)
              TextButton.icon(
                onPressed: () => open('/pesanan/${detail.id}/poin'),
                icon: const Icon(Icons.star_border_rounded, size: 20),
                label: const Text('Gunakan poin'),
              ),
            TextButton.icon(
              onPressed: () => context.push('/pesanan/${detail.id}/nota'),
              icon: const Icon(Icons.receipt_long_outlined, size: 19),
              label: const Text('Lihat Nota'),
            ),
          ],
        ),
        if (!detail.sudahLunas) ...[
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => open('/pesanan/${detail.id}/pembayaran'),
            child: const Text('Lihat pilihan pembayaran'),
          ),
        ],
        if (detail.pembayaran.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  'Riwayat pembayaran',
                  style: theme.textTheme.bodyMedium,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  for (final p in detail.pembayaran)
                    _SummaryRow(
                      label: p.tglBayar == null
                          ? p.metode
                          : '${formatTanggalSingkat(p.tglBayar!)} · ${p.metode}',
                      value: formatRupiah(p.nominalBayar),
                      bold: true,
                      valueColor: theme.colorScheme.onSurface,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style =
        (bold ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)
            ?.copyWith(
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              color: bold ? colors.onSurface : colors.onSurfaceVariant,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: style?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? (bold ? colors.primary : colors.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  const _PinCard({required this.pin});
  final String? pin;
  @override
  Widget build(BuildContext context) {
    final value = pin;
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(
          Icons.lock_outline_rounded,
          color: theme.colorScheme.primary,
        ),
        title: Text('PIN Pengambilan', style: theme.textTheme.titleSmall),
        subtitle: Text(
          'Buka saat mengambil cucian.',
          style: theme.textTheme.bodySmall,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    letterSpacing: 6,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Salin PIN',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN disalin.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
          Text(
            'Tunjukkan PIN ini saat mengambil cucian.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        AppCard(child: child),
      ],
    ),
  );
}
