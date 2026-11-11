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
                _SectionCard(
                  title: 'Perjalanan cucian',
                  child: TimelineStatus(steps: detail.timeline),
                ),
                _ItemsCard(items: detail.items),
                _PaymentCard(detail: detail),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.push('/pesanan/${detail.id}/nota'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Lihat Nota'),
                  ),
                ),
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
    final colors = theme.colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 20),
      color: colors.primaryContainer,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (MediaQuery.textScalerOf(context).scale(14) < 20) ...[
            const AppArtwork(asset: AppAssets.home, width: 70, height: 70),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.noNota, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                StatusChip(status: detail.status, label: detail.statusLabel),
                const SizedBox(height: 12),
                Text('Estimasi selesai', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  detail.tglEstimasi == null
                      ? 'Menunggu estimasi'
                      : formatEstimasi(detail.tglEstimasi!),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatBerat(detail.totalBerat)} · Masuk ${formatTanggal(detail.tglMasuk)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (detail.tglAktual != null)
                  Text(
                    'Selesai ${formatTanggal(detail.tglAktual!)}',
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
    final colors = theme.colorScheme;
    final lunas = detail.sudahLunas;

    return _SectionCard(
      title: 'Pembayaran',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(
            label: 'Total biaya',
            value: formatRupiah(detail.totalBiaya),
          ),
          if (detail.diskon > 0)
            _SummaryRow(
              label: 'Diskon',
              value: '-${formatRupiah(detail.diskon)}',
              valueColor: colors.primary,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: TicketDivider(),
          ),
          _SummaryRow(
            label: 'Grand total',
            value: formatRupiah(detail.grandTotal),
            bold: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  lunas ? Icons.verified_outlined : Icons.info_outline_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lunas ? 'Lunas' : 'Belum dibayar',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (detail.metodePembayaran != null &&
                    detail.metodePembayaran!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      detail.metodePembayaran!,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!lunas) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await context.push('/pesanan/${detail.id}/pembayaran');
                if (context.mounted) {
                  ref.invalidate(transaksiDetailProvider(detail.id));
                }
              },
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Lihat pilihan pembayaran'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await context.push('/pesanan/${detail.id}/poin');
                if (context.mounted) {
                  ref.invalidate(transaksiDetailProvider(detail.id));
                }
              },
              icon: const Icon(Icons.stars_outlined),
              label: const Text('Gunakan poin'),
            ),
          ],
          if (detail.pembayaran.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: TicketDivider(),
            ),
            for (final pembayaran in detail.pembayaran)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        pembayaran.tglBayar == null
                            ? pembayaran.metode
                            : '${formatTanggalSingkat(pembayaran.tglBayar!)} · ${pembayaran.metode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        formatRupiah(pembayaran.nominalBayar),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
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
    final colors = theme.colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: colors.primary, width: 2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN Pengambilan',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tunjukkan PIN ini saat mengambil cucian.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('PIN disalin.')));
              },
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.primary,
              ),
              icon: const Icon(Icons.copy_outlined, size: 20),
              tooltip: 'Salin PIN',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
