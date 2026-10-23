import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../application/pesanan_controller.dart';
import '../data/transaksi_detail.dart';
import 'widgets/timeline_status.dart';

final transaksiDetailProvider =
    FutureProvider.autoDispose.family<TransaksiDetail, int>((ref, id) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: AsyncValueView<TransaksiDetail>(
        value: async,
        onRetry: () => ref.invalidate(transaksiDetailProvider(id)),
        loadingBuilder: (context) => const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingList(itemCount: 3, itemHeight: 120),
        ),
        builder: (context, detail) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _HeaderCard(detail: detail),
              _ItemsCard(items: detail.items),
              _PaymentCard(detail: detail),
              _PinCard(pin: detail.pinPengambilan),
              _SectionCard(
                title: 'Status Pesanan',
                child: TimelineStatus(steps: detail.timeline),
              ),
            ],
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

    return _SectionCard(
      title: 'Ringkasan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.noNota,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: detail.status, label: detail.statusLabel),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.login_rounded,
            label: 'Masuk',
            value: formatTanggal(detail.tglMasuk),
          ),
          if (detail.tglEstimasi != null)
            _InfoLine(
              icon: Icons.event_available_outlined,
              label: 'Estimasi selesai',
              value: formatTanggal(detail.tglEstimasi!),
            ),
          if (detail.tglAktual != null)
            _InfoLine(
              icon: Icons.task_alt_rounded,
              label: 'Selesai',
              value: formatTanggal(detail.tglAktual!),
            ),
          _InfoLine(
            icon: Icons.scale_outlined,
            label: 'Total berat',
            value: formatBerat(detail.totalBerat),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/pesanan/${detail.id}/nota'),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Lihat Nota'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
          ? Text(
              'Belum ada rincian layanan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const Divider(height: 20),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.namaLayanan,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatBerat(item.berat)} × ${formatRupiah(item.hargaSatuan)}/kg',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatRupiah(item.subtotal),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.detail});

  final TransaksiDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lunas = detail.sudahLunas;

    return _SectionCard(
      title: 'Pembayaran',
      child: Column(
        children: [
          _SummaryRow(label: 'Total biaya', value: formatRupiah(detail.totalBiaya)),
          if (detail.diskon > 0)
            _SummaryRow(
              label: 'Diskon',
              value: '-${formatRupiah(detail.diskon)}',
              valueColor: AppColors.success,
            ),
          const Divider(height: 20),
          _SummaryRow(
            label: 'Grand total',
            value: formatRupiah(detail.grandTotal),
            bold: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                lunas
                    ? Icons.verified_rounded
                    : Icons.error_outline_rounded,
                size: 17,
                color: lunas ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                lunas ? 'Lunas' : 'Belum dibayar',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: lunas ? AppColors.success : AppColors.warning,
                ),
              ),
              const Spacer(),
              if (detail.metodePembayaran != null &&
                  detail.metodePembayaran!.isNotEmpty)
                Text(
                  detail.metodePembayaran!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          if (detail.pembayaran.isNotEmpty) ...[
            const Divider(height: 24),
            for (final pembayaran in detail.pembayaran)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pembayaran.tglBayar == null
                            ? pembayaran.metode
                            : '${formatTanggalSingkat(pembayaran.tglBayar!)} · ${pembayaran.metode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    Text(
                      formatRupiah(pembayaran.nominalBayar),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
    final style = (bold ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)
        ?.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: valueColor ?? (bold ? AppColors.text : AppColors.muted),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(
            value,
            style: bold
                ? style
                : theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
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

    return _SectionCard(
      title: 'PIN Pengambilan',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tunjukkan PIN ini saat mengambil cucian.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN disalin.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Salin PIN',
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
