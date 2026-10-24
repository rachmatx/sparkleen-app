import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _HomeHero(pelanggan: pelanggan, nama: nama),
              Transform.translate(
                offset: const Offset(0, -48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AsyncValueView<TransaksiRingkas?>(
                        value: ref.watch(pesananAktifProvider),
                        loadingBuilder: (context) =>
                            const LoadingList(itemCount: 1, itemHeight: 186),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.add_rounded,
                              label: 'Pesan',
                              color: AppColors.primary,
                              background: AppColors.primarySoft,
                              onTap: () => context.go('/pesanan'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.search_rounded,
                              label: 'Lacak',
                              color: AppColors.aqua,
                              background: AppColors.aquaSoft,
                              onTap: () => context.go('/pesanan'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'WhatsApp',
                              color: AppColors.mint,
                              background: AppColors.mintSoft,
                              onTap: () => _copyWhatsapp(context, ref),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const _SectionHeader(title: 'Layanan & harga'),
                      const SizedBox(height: 12),
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
                            for (
                              var index = 0;
                              index < layanan.length;
                              index++
                            ) ...[
                              _LayananTile(
                                layanan: layanan[index],
                                index: index,
                              ),
                              if (index != layanan.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _PoinCard(pelanggan: pelanggan),
                      const SizedBox(height: 116),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.pelanggan, required this.nama});

  final Pelanggan? pelanggan;
  final String nama;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.aqua.withValues(alpha: 0.28),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo,',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          nama.isNotEmpty
                              ? nama.substring(0, 1).toUpperCase()
                              : 'S',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        _HeroStat(
                          label: 'Poin',
                          value: '${pelanggan?.poin ?? 0}',
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        _HeroStat(
                          label: 'Total transaksi',
                          value: formatRupiah(pelanggan?.totalTransaksi ?? 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

double _progressFor(String status) {
  switch (status.toLowerCase()) {
    case 'menunggu':
      return 0.15;
    case 'proses':
      return 0.45;
    case 'setrika':
      return 0.75;
    case 'selesai':
    case 'diambil':
      return 1;
    default:
      return 0.2;
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.transaksi, required this.onTap});

  final TransaksiRingkas transaksi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = _progressFor(transaksi.status);

    return AppCard(
      shadow: AppColors.elevatedShadow,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Pesanan aktif',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.soft,
                    ),
                  ),
                  const Spacer(),
                  StatusChip(
                    status: transaksi.status,
                    label: transaksi.statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                transaksi.noNota,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFEFF1F8),
                  valueColor: const AlwaysStoppedAnimation(
                    Color(0xFF4F46E5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaksi.tglEstimasi == null
                          ? 'Menunggu estimasi'
                          : 'Estimasi ${formatTanggalSingkat(transaksi.tglEstimasi!)}',
                      style: textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _InfoBlock(
                        label: 'Masuk',
                        value: formatTanggalSingkat(transaksi.tglMasuk),
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
                    const SizedBox(width: 10),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: AppColors.primary,
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
        Text(label, style: textTheme.labelSmall),
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
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      shadow: AppColors.softShadow,
      padding: const EdgeInsets.symmetric(vertical: 14),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
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
    );
  }
}

class _LayananTile extends StatelessWidget {
  const _LayananTile({required this.layanan, required this.index});

  final Layanan layanan;
  final int index;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const palette = [
      (AppColors.primary, AppColors.primarySoft),
      (AppColors.aqua, AppColors.aquaSoft),
      (AppColors.violet, Color(0xFFF3EDFF)),
    ];
    final (color, background) = palette[index % palette.length];

    return AppCard(
      shadow: AppColors.softShadow,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.local_laundry_service_outlined,
              size: 21,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layanan.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
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
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text('/kg', style: textTheme.labelSmall),
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
    final whiteMuted = textTheme.labelSmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.7),
    );

    return AppCard(
      padding: const EdgeInsets.all(18),
      gradient: AppColors.pointsGradient,
      shadow: const [
        BoxShadow(
          color: Color(0x47312E81),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
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
                formatRupiah(pelanggan?.totalTransaksi ?? 0),
                style: textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
