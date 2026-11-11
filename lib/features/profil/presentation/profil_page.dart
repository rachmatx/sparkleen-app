import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sync/customer_refresh.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_artwork.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../auth/application/auth_controller.dart';
import '../../pengaturan/presentation/settings_page.dart';

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
    return AppBackdrop(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(customerRefreshProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Profil',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pengaturan',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => context.push('/pengaturan'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (pelanggan == null)
                  const LoadingList()
                else ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          pelanggan.nama.trim().isEmpty
                              ? '?'
                              : pelanggan.nama
                                    .trim()
                                    .characters
                                    .first
                                    .toUpperCase(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pelanggan.nama,
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              pelanggan.kode,
                              style: theme.textTheme.bodySmall,
                            ),
                            TextButton(
                              onPressed: () => openEditProfile(context),
                              child: const Text('Ubah profil'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.87,
                    ),
                    onTap: () => context.push('/poin'),
                    child: Row(
                      children: [
                        const AppArtwork(
                          asset: AppAssets.points,
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pelanggan.poin} poin',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const Text('Siap ditukar jadi potongan'),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 28,
                    runSpacing: 16,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total belanja',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            formatRupiah(pelanggan.totalTransaksi),
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status akun', style: theme.textTheme.bodySmall),
                          Text(
                            'Aktif',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Informasi akun', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.phone_android_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text('Nomor telepon'),
                          subtitle: Text(pelanggan.noTelp),
                        ),
                        const Divider(indent: 16, endIndent: 16),
                        SettingsTile(
                          icon: Icons.location_on_outlined,
                          title: 'Alamat penjemputan',
                          subtitle: pelanggan.alamat.isEmpty
                              ? 'Lengkapi alamat'
                              : pelanggan.alamat,
                          onTap: () => openEditProfile(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Aktivitas', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SettingsTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'Riwayat pesanan',
                          onTap: () => context.go('/pesanan'),
                        ),
                        const Divider(indent: 16, endIndent: 16),
                        SettingsTile(
                          icon: Icons.stars_outlined,
                          title: 'Tukar dan riwayat poin',
                          onTap: () => context.push('/poin'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'sparkleen laundry',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
