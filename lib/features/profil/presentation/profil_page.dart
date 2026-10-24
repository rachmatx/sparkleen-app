import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/pelanggan.dart';
import 'edit_profil_page.dart';

class ProfilPage extends ConsumerWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final pelanggan = switch (auth.value) {
      AuthAuthenticated(:final pelanggan) => pelanggan,
      _ => null,
    };

    if (pelanggan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: auth.isLoading
              ? const LoadingList()
              : ErrorState(
                  error:
                      auth.error ??
                      const ApiException(
                        code: 'NO_SESSION',
                        message: 'Sesi tidak ditemukan. Silakan masuk kembali.',
                      ),
                  onRetry: () => ref.invalidate(authControllerProvider),
                ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 116),
          children: [
            Text('Profil', style: textTheme.headlineMedium),
            const SizedBox(height: 2),
            Text(
              'Kelola data akun dan pengaturan kamu.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            _ProfileHeader(pelanggan: pelanggan),
            const SizedBox(height: 18),
            Text('Detail akun', style: textTheme.titleSmall),
            const SizedBox(height: 10),
            _DetailCard(pelanggan: pelanggan),
            const SizedBox(height: 20),
            AppGradientButton(
              label: 'Ubah Profil',
              icon: Icons.edit_outlined,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const EditProfilPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                backgroundColor: AppColors.dangerSoft,
                side: const BorderSide(color: Color(0xFFFAD2DD)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Keluar Akun'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu perlu masuk kembali untuk melihat pesanan dan poin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).logout();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.pelanggan});

  final Pelanggan pelanggan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nama = pelanggan.nama.trim();
    final initial = nama.isEmpty ? '?' : nama.substring(0, 1).toUpperCase();
    final whiteMuted = theme.textTheme.labelSmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.68),
    );

    return AppCard(
      padding: const EdgeInsets.all(20),
      gradient: AppColors.heroGradient,
      shadow: AppColors.elevatedShadow,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  initial,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pelanggan.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        pelanggan.kode,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Poin', style: whiteMuted),
                      const SizedBox(height: 2),
                      Text(
                        '${pelanggan.poin}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total transaksi', style: whiteMuted),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(pelanggan.totalTransaksi),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.pelanggan});

  final Pelanggan pelanggan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      shadow: AppColors.softShadow,
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.phone_android_rounded,
            label: 'Nomor telepon',
            value: pelanggan.noTelp,
          ),
          const Divider(height: 24, color: AppColors.border),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Alamat',
            value: pelanggan.alamat.isEmpty ? '-' : pelanggan.alamat,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
