import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/widgets/app_artwork.dart';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppBackdrop(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
            children: [
              Text('Profil', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Detail akun, poin, dan informasi kontak.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (pelanggan == null)
                auth.isLoading
                    ? const LoadingList()
                    : ErrorState(
                        error:
                            auth.error ??
                            const ApiException(
                              code: 'NO_SESSION',
                              message: 'Sesi tidak ditemukan. Silakan masuk kembali.',
                            ),
                        onRetry: () => ref.invalidate(authControllerProvider),
                      )
              else ...[
                _ProfileHeader(pelanggan: pelanggan),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/poin'),
                  icon: const Icon(Icons.stars_outlined),
                  label: const Text('Tukar dan riwayat poin'),
                ),
                const SizedBox(height: 26),
                Text('Informasi akun', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.phone_android_rounded,
                        label: 'Nomor telepon',
                        value: pelanggan.noTelp,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: TicketDivider(),
                      ),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Alamat',
                        value: pelanggan.alamat.isEmpty
                            ? 'Belum ada alamat'
                            : pelanggan.alamat,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppButton(
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
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar Akun'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sparkleen Laundry',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
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
    final colors = theme.colorScheme;
    final nama = pelanggan.nama.trim();
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nama.isEmpty ? '?' : nama.characters.first.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pelanggan.nama, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text(
                      pelanggan.kode,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: TicketDivider(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppArtwork(
                          asset: AppAssets.points,
                          width: 32,
                          height: 32,
                          fallbackIcon: Icons.auto_awesome_outlined,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${pelanggan.poin}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('Poin terkumpul', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pelanggan.totalTransaksi} transaksi',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text('Bersama Sparkleen', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
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
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
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
