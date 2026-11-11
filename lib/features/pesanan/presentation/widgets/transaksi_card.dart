import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/widgets/app_artwork.dart';
import 'order_stages.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../data/transaksi_ringkas.dart';

class TransaksiCard extends StatelessWidget {
  const TransaksiCard({super.key, required this.transaksi, this.onTap});
  final TransaksiRingkas transaksi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(
                status: transaksi.status,
                label: transaksi.statusLabel,
              ),
              Text(transaksi.noNota, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const AppArtwork(asset: AppAssets.home, width: 64, height: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaksi.isAktif ? 'Estimasi selesai' : 'Tanggal masuk',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaksi.isAktif
                          ? (transaksi.tglEstimasi == null
                                ? 'Menunggu estimasi'
                                : formatEstimasi(transaksi.tglEstimasi!))
                          : formatTanggalSingkat(transaksi.tglMasuk),
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (transaksi.isAktif) ...[
            const SizedBox(height: 12),
            OrderStages(status: transaksi.status),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  formatBerat(transaksi.totalBerat),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  formatRupiah(transaksi.grandTotal),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.primary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
