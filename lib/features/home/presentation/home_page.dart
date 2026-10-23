import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/pelanggan.dart';
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
      // Kegagalan ditampilkan per bagian oleh AsyncValueView.
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              _Greeting(nama: nama),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Pesanan aktif',
                actionLabel: 'Lihat semua',
                onAction: () => context.go('/pesanan'),
              ),
              const SizedBox(height: 10),
              AsyncValueView<TransaksiRingkas?>(
                value: ref.watch(pesananAktifProvider),
                loadingBuilder: (context) =>
                    const LoadingList(itemCount: 1, itemHeight: 142),
                onRetry: () => ref.invalidate(pesananAktifProvider),
                isEmpty: (transaksi) => transaksi == null,
                emptyBuilder: (context) => EmptyState(
                  message: 'Belum ada pesanan aktif.',
                  icon: Icons.check_circle_outline_rounded,
                  actionLabel: 'Lihat riwayat',
                  onAction: () => context.go('/pesanan'),
                ),
                builder: (context, transaksi) => _ActiveOrderCard(
                  transaksi: transaksi!,
                  onTap: () => context.push('/pesanan/${transaksi.id}'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_rounded,
                      label: 'Pesan',
                      onTap: () => context.go('/pesanan'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.search_rounded,
                      label: 'Lacak',
                      onTap: () => context.go('/pesanan'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'WhatsApp',
                      onTap: () => _copyWhatsapp(context, ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionHeader(title: 'Layanan & harga'),
              const SizedBox(height: 10),
              AsyncValueView<List<Layanan>>(
                value: ref.watch(layananProvider),
                loadingBuilder: (context) =>
                    const LoadingList(itemCount: 3, itemHeight: 72),
                onRetry: () => ref.invalidate(layananProvider),
                isEmpty: (layanan) => layanan.isEmpty,
                emptyBuilder: (context) => const EmptyState(
                  message: 'Belum ada layanan tersedia.',
                  icon: Icons.local_laundry_service_outlined,
                ),
                builder: (context, layanan) => Column(
                  children: [
                    for (var index = 0; index < layanan.length; index++) ...[
                      _LayananTile(layanan: layanan[index]),
                      if (index != layanan.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _PoinCard(pelanggan: pelanggan),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.nama});

  final String nama;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo,',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : 'S',
            style: textTheme.titleMedium?.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.transaksi, required this.onTap});

  final TransaksiRingkas transaksi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaksi.noNota,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    status: transaksi.status,
                    label: transaksi.statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Masuk ${formatTanggalSingkat(transaksi.tglMasuk)}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InfoBlock(
                      label: 'Estimasi',
                      value: transaksi.tglEstimasi == null
                          ? '-'
                          : formatTanggalSingkat(transaksi.tglEstimasi!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoBlock(
                      label: 'Berat',
                      value: formatBerat(transaksi.totalBerat),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoBlock(
                      label: 'Total',
                      value: formatRupiah(transaksi.grandTotal),
                      highlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Lihat detail',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.primary : AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayananTile extends StatelessWidget {
  const _LayananTile({required this.layanan});

  final Layanan layanan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_laundry_service_outlined,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(layanan.nama, style: textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  'Estimasi ${layanan.estimasiHari} hari',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(layanan.hargaPerKg),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text('/kg', style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoinCard extends StatelessWidget {
  const _PoinCard({required this.pelanggan});

  final Pelanggan? pelanggan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final whiteMuted = textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.72),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Poin kamu', style: whiteMuted),
                const SizedBox(height: 2),
                Text(
                  '${pelanggan?.poin ?? 0} poin',
                  style: textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total transaksi', style: whiteMuted),
              const SizedBox(height: 2),
              Text(
                '${pelanggan?.totalTransaksi ?? 0}x',
                style: textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
