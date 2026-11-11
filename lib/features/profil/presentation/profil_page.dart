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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
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
                const SizedBox(height: 16),
                if (pelanggan == null)
                  const LoadingList()
                else ...[
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Text(
                          pelanggan.nama.trim().isEmpty
                              ? '?'
                              : pelanggan.nama
                                    .trim()
                                    .characters
                                    .first
                                    .toUpperCase(),
                          style: theme.textTheme.headlineLarge?.copyWith(
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
                              'Pelanggan Sparkleen · ${pelanggan.kode}',
                              style: theme.textTheme.bodySmall,
                            ),
                            TextButton(
                              onPressed: () => openEditProfile(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(48, 32),
                                alignment: Alignment.centerLeft,
                              ),
                              child: const Text('Ubah profil'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    color: theme.colorScheme.primaryContainer,
                    onTap: () => context.push('/poin'),
                    child: Row(
                      children: [
                        const AppArtwork(
                          asset: AppAssets.points,
                          width: 44,
                          height: 44,
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: theme.colorScheme.outlineVariant,
                        ),
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
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total belanja',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(pelanggan.totalTransaksi),
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: theme.colorScheme.outlineVariant,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status akun',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aktif',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Informasi akun', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          titleTextStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          subtitleTextStyle: theme.textTheme.bodySmall,
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
                  const SizedBox(height: 16),
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
