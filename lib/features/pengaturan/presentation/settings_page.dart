import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_config.dart';
import '../../../core/app_info.dart';
import '../../../core/settings/appearance_settings.dart';
import '../../../core/settings/server_settings.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/application/auth_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final server = ref.watch(serverAddressProvider);
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengaturan')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              'Sesuaikan Sparkleen untukmu.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            _group(context, 'Akun & keamanan', [
              SettingsTile(
                icon: Icons.person_outline,
                title: 'Ubah profil',
                onTap: () => openEditProfile(context),
              ),
              SettingsTile(
                icon: Icons.fingerprint,
                title: 'PIN & biometrik',
                subtitle: 'Login dan konfirmasi tagihan',
                onTap: () => context.push('/keamanan'),
              ),
            ]),
            _group(context, 'Preferensi', [
              SettingsTile(
                icon: Icons.notifications_none,
                title: 'Notifikasi',
                subtitle: 'Pembaruan pesanan',
                onTap: () => context.push('/notifikasi'),
              ),
              SettingsTile(
                icon: Icons.brightness_6_outlined,
                title: 'Tampilan',
                value: themeModeLabel(mode),
                onTap: () => _appearance(context, ref),
              ),
            ]),
            if (ApiConfig.isPreview)
              _group(context, 'Koneksi', [
                SettingsTile(
                  icon: Icons.dns_outlined,
                  title: 'Konfigurasi server',
                  subtitle: server,
                  onTap: () => context.push('/server'),
                ),
              ]),
            _group(context, 'Tentang', [
              SettingsTile(
                icon: Icons.info_outline,
                title: 'Tentang Sparkleen',
                value: AppInfo.version,
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Sparkleen',
                  applicationVersion: '${AppInfo.versionLabel} · Pratinjau',
                  children: const [
                    Text(
                      'Laundry jadi ringan. Pembayaran online pada versi pengujian menggunakan simulasi Smart Pay.',
                    ),
                  ],
                ),
              ),
            ]),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  'Keluar dari akun',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => _logout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> rows) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(indent: 18, endIndent: 18),
                    rows[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      );
  Future<void> _appearance(BuildContext context, WidgetRef ref) async {
    final mode = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tampilan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final mode in ThemeMode.values)
                ListTile(
                  title: Text(themeModeLabel(mode)),
                  leading: Icon(
                    mode == ThemeMode.system
                        ? Icons.brightness_auto_outlined
                        : mode == ThemeMode.light
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  trailing: ref.read(themeModeProvider) == mode
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, mode),
                ),
            ],
          ),
        ),
      ),
    );
    if (mode == null) return;
    try {
      await ref.read(themeModeProvider.notifier).change(mode);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilihan tampilan belum tersimpan. Coba lagi.'),
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Masuk kembali dengan PIN akun untuk melihat pesananmu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yes == true) await ref.read(authControllerProvider.notifier).logout();
  }
}

void openEditProfile(BuildContext context) => context.push('/ubah-profil');

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final large = MediaQuery.textScalerOf(context).scale(14) > 18;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (value != null && large)
                    Text(value!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (value != null && !large) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 88),
                child: Text(value!, style: theme.textTheme.bodySmall),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
