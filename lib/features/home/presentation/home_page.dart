import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_artwork.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/application/auth_controller.dart';
import '../../pesanan/data/transaksi_ringkas.dart';
import '../application/home_providers.dart';
import '../data/layanan.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(layananProvider);
    ref.invalidate(outletProvider);
    ref.invalidate(pesananAktifProvider);
    try {
      await Future.wait([
        ref.read(layananProvider.future),
        ref.read(outletProvider.future),
        ref.read(pesananAktifProvider.future),
      ]);
    } on Object {
      // Each section displays its own retry state.
    }
  }

  Future<void> _copyWhatsapp(BuildContext context, WidgetRef ref) async {
    final outlet = ref.read(outletProvider).value;
    if (outlet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Info outlet belum tersedia.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: outlet.noWa));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nomor WhatsApp disalin: ${outlet.noWa}')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).value;
    final pelanggan = auth is AuthAuthenticated ? auth.pelanggan : null;
    final nama = pelanggan?.nama.isNotEmpty == true
        ? pelanggan!.nama
        : 'Pelanggan';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppBackdrop(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
              children: [
                Row(
                  children: [
                    const BrandMark(size: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'sparkleen',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppArtwork(
                            asset: AppAssets.points,
                            width: 24,
                            height: 24,
                            fallbackIcon: Icons.auto_awesome_outlined,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${pelanggan?.poin ?? 0} poin',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _WelcomeCard(nama: nama),
                const SizedBox(height: 24),
                AsyncValueView<TransaksiRingkas?>(
                  value: ref.watch(pesananAktifProvider),
                  loadingBuilder: (context) =>
                      const LoadingList(itemCount: 1, itemHeight: 200),
                  onRetry: () => ref.invalidate(pesananAktifProvider),
                  isEmpty: (transaksi) => transaksi == null,
                  emptyBuilder: (context) => EmptyState(
                    message: 'Belum ada pesanan aktif.',
                    icon: Icons.local_laundry_service_outlined,
                    illustrationAsset: AppAssets.emptyActiveOrder,
                    actionLabel: 'Lihat riwayat',
                    onAction: () => context.go('/pesanan'),
                  ),
                  builder: (context, transaksi) => _ActiveOrderCard(
                    transaksi: transaksi!,
                    onTap: () => context.push('/pesanan/${transaksi.id}'),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Lihat semua pesanan',
                  icon: Icons.receipt_long_outlined,
                  onPressed: () => context.go('/pesanan'),
                ),
                const SizedBox(height: 28),
                Text('Layanan & harga', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Pilih perawatan yang pas untuk cucianmu.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                AsyncValueView<List<Layanan>>(
                  value: ref.watch(layananProvider),
                  loadingBuilder: (context) =>
                      const LoadingList(itemCount: 2, itemHeight: 74),
                  onRetry: () => ref.invalidate(layananProvider),
                  isEmpty: (layanan) => layanan.isEmpty,
                  emptyBuilder: (context) => const EmptyState(
                    message: 'Belum ada layanan tersedia.',
                    icon: Icons.local_laundry_service_outlined,
                  ),
                  builder: (context, layanan) => AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < layanan.length;
                          index++
                        ) ...[
                          _LayananTile(layanan: layanan[index]),
                          if (index < layanan.length - 1) const TicketDivider(),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Biaya cucian dihitung dari berat dan layanan yang tercatat di nota.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${pelanggan?.totalTransaksi ?? 0} transaksi',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text('Bersama Sparkleen', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _copyWhatsapp(context, ref),
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Salin nomor WhatsApp outlet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.nama});

  final String nama;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      color: AppColors.primarySoft,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageWidth = constraints.maxWidth < 300 ? 104.0 : 144.0;
          final stackArtwork = MediaQuery.textScalerOf(context).scale(16) > 22;
          final greeting = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang,',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                nama,
                style: textTheme.headlineSmall?.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: 6),
              Text(
                'Urusan cucian, lebih ringan.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          );
          if (stackArtwork) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                greeting,
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: AppArtwork(
                    asset: AppAssets.home,
                    width: 180,
                    height: 90,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: greeting),
              const SizedBox(width: 10),
              AppArtwork(
                asset: AppAssets.home,
                width: imageWidth,
                height: imageWidth / 1.65,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.transaksi, required this.onTap});
  final TransaksiRingkas transaksi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: AppColors.primary),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'CUCIAN AKTIF',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        letterSpacing: 1.4,
                      ),
                    ),
                    StatusChip(
                      status: transaksi.status,
                      label: transaksi.statusLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(transaksi.noNota, style: theme.textTheme.titleMedium),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 22,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimasi selesai',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            transaksi.tglEstimasi == null
                                ? 'Menunggu estimasi'
                                : formatTanggal(transaksi.tglEstimasi!),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const TicketDivider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatBerat(transaksi.totalBerat),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      formatRupiah(transaksi.grandTotal),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lihat perjalanan cucian',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LayananTile extends StatelessWidget {
  const _LayananTile({required this.layanan});
  final Layanan layanan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final artwork = AppAssets.serviceArtwork(
      name: layanan.nama,
      assetKey: layanan.assetKey,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: artwork == null
                ? Icon(
                    Icons.local_laundry_service_outlined,
                    size: 26,
                    color: colors.primary,
                  )
                : Padding(
                    padding: const EdgeInsets.all(3),
                    child: AppArtwork(asset: artwork, width: 54, height: 54),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(layanan.nama, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  '± ${layanan.estimasiHari} hari',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRupiah(layanan.hargaPerKg),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleSmall,
                ),
                Text('per kg', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
