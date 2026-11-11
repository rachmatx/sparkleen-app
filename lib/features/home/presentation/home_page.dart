import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_artwork.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/sync/customer_refresh.dart';
import '../../auth/application/auth_controller.dart';
import '../../notifikasi/presentation/notification_page.dart';
import '../../pesanan/data/transaksi_ringkas.dart';
import '../../pesanan/presentation/widgets/order_stages.dart';
import '../application/home_providers.dart';
import '../data/layanan.dart';
import '../data/outlet_info.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _refresh(WidgetRef ref) =>
      ref.read(customerRefreshProvider.notifier).refresh();

  Future<void> _copyWhatsapp(BuildContext context, OutletInfo outlet) async {
    if (outlet.noWa.trim().isEmpty) return;
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandMark(size: 36),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'sparkleen',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const NotificationBell(),
                    TextButton.icon(
                      onPressed: () => context.go('/profil'),
                      style: TextButton.styleFrom(
                        backgroundColor: colors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: BorderSide(color: colors.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const AppArtwork(
                        asset: AppAssets.points,
                        width: 22,
                        height: 22,
                        fallbackIcon: Icons.auto_awesome_outlined,
                      ),
                      label: Text('${pelanggan?.poin ?? 0} poin'),
                    ),
                  ],
                ),
                if (ref.watch(customerRefreshProvider).failed)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Pembaruan belum lengkap. Data terakhir tetap ditampilkan; tarik untuk mencoba lagi.',
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                const SizedBox(height: 24),
                _WelcomeHeader(nama: nama),
                const SizedBox(height: 16),
                AppCard(
                  onTap: () => context.push('/jemput'),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jemput laundry',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Ajukan jadwal dan pantau penjemputan',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pesanan aktif',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/pesanan'),
                      child: const Text('Semua'),
                    ),
                  ],
                ),
                AsyncValueView<TransaksiRingkas?>(
                  value: ref.watch(pesananAktifProvider),
                  loadingBuilder: (context) =>
                      const LoadingList(itemCount: 1, itemHeight: 210),
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
                const SizedBox(height: 24),
                Text('Layanan laundry', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                AsyncValueView<List<Layanan>>(
                  value: ref.watch(layananProvider),
                  loadingBuilder: (context) =>
                      const LoadingList(itemCount: 2, itemHeight: 100),
                  onRetry: () => ref.invalidate(layananProvider),
                  isEmpty: (layanan) => layanan.isEmpty,
                  emptyBuilder: (context) => const EmptyState(
                    message: 'Belum ada layanan tersedia.',
                    icon: Icons.local_laundry_service_outlined,
                  ),
                  builder: (context, layanan) => LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns =
                          constraints.maxWidth >= 330 &&
                          MediaQuery.textScalerOf(context).scale(14) <= 18;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final item in layanan)
                            SizedBox(
                              width: twoColumns
                                  ? (constraints.maxWidth - 10) / 2
                                  : constraints.maxWidth,
                              child: _ServiceCard(layanan: item),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Biaya mengikuti berat dan layanan yang tercatat di nota.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                AsyncValueView<OutletInfo>(
                  value: ref.watch(outletProvider),
                  onRetry: () => ref.invalidate(outletProvider),
                  loadingBuilder: (_) =>
                      const LoadingList(itemCount: 1, itemHeight: 84),
                  builder: (context, outlet) => AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              color: colors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    outlet.nama.isEmpty
                                        ? 'Outlet Sparkleen'
                                        : outlet.nama,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  if (outlet.alamat.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      outlet.alamat,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                  if (outlet.jamBuka.isNotEmpty &&
                                      outlet.jamTutup.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Jam operasional ${outlet.jamBuka}–${outlet.jamTutup}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (outlet.noWa.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _copyWhatsapp(context, outlet),
                            icon: const Icon(Icons.copy_outlined, size: 18),
                            label: const Text('Salin nomor WhatsApp outlet'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${pelanggan?.totalTransaksi ?? 0} transaksi',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.nama});
  final String nama;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selamat datang,', style: text.bodySmall),
        const SizedBox(height: 4),
        Text(nama, style: text.headlineMedium),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.textScalerOf(context).scale(16) > 22) return greeting;
        return Row(
          children: [
            Expanded(child: greeting),
            const SizedBox(width: 8),
            const IllustrationPanel(
              asset: AppAssets.home,
              width: 82,
              height: 62,
              padding: EdgeInsets.all(4),
            ),
          ],
        );
      },
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
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
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
              Text(transaksi.noNota, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 18),
          Text('Estimasi selesai', style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            transaksi.tglEstimasi == null
                ? 'Menunggu estimasi'
                : formatEstimasi(transaksi.tglEstimasi!),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          OrderStages(status: transaksi.status),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${formatBerat(transaksi.totalBerat)} · ${formatRupiah(transaksi.grandTotal)}',
                style: theme.textTheme.bodyMedium,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Detail pesanan',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.layanan});
  final Layanan layanan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = AppAssets.serviceArtwork(
      name: layanan.nama,
      assetKey: layanan.assetKey,
    );
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (asset != null) ...[
                  IllustrationPanel(asset: asset, width: 100, height: 86),
                  const SizedBox(height: 16),
                ],
                Text(layanan.nama, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  '${formatRupiah(layanan.hargaPerKg)} per kg · Estimasi ${layanan.estimasiHari} hari',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Total cucian mengikuti berat dan layanan yang tercatat pada nota.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (asset != null)
            IllustrationPanel(
              asset: asset,
              width: 66,
              height: 58,
              padding: const EdgeInsets.all(3),
            )
          else
            Icon(
              Icons.local_laundry_service_outlined,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(height: 12),
          Text(layanan.nama, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            formatRupiah(layanan.hargaPerKg),
            style: theme.textTheme.titleLarge,
          ),
          Text(
            'per kg · ${layanan.estimasiHari} hari',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
