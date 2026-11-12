import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../data/transaksi_ringkas.dart';
import 'order_stages.dart';

class TransaksiCard extends StatelessWidget {
  const TransaksiCard({super.key, required this.transaksi, this.onTap});
  final TransaksiRingkas transaksi;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expandedText = MediaQuery.textScalerOf(context).scale(14) > 20;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusChip(
                status: transaksi.status,
                label: transaksi.customerStatusLabel,
              ),
              Text(transaksi.noNota, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!expandedText) ...[
                const AppArtwork(asset: AppAssets.home, width: 100, height: 98),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pesanan laundry', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${formatBerat(transaksi.totalBerat)} · ${formatRupiah(transaksi.grandTotal)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      transaksi.isAktif ? 'Estimasi selesai' : 'Tanggal masuk',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaksi.isAktif
                          ? (transaksi.tglEstimasi == null
                                ? 'Menunggu estimasi'
                                : formatEstimasi(transaksi.tglEstimasi!))
                          : formatTanggalSingkat(transaksi.tglMasuk),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (transaksi.isAktif) ...[
            const SizedBox(height: 10),
            OrderStages(status: transaksi.status, workflow: transaksi.workflow),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  'Lihat detail',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 19,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
