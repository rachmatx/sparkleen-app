import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/notification_settings.dart';
import '../../../core/widgets/app_card.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _busy = false;

  Future<void> _change({bool? showBadge, bool? autoRefresh}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .change(showBadge: showBadge, autoRefresh: autoRefresh);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferensi belum tersimpan. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(notificationPreferencesProvider);
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengaturan notifikasi')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Pembaruan di aplikasi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Jumlah belum dibaca'),
                    subtitle: const Text(
                      'Tampilkan angka pada ikon notifikasi.',
                    ),
                    value: value.showBadge,
                    onChanged: _busy
                        ? null
                        : (value) => _change(showBadge: value),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  SwitchListTile.adaptive(
                    title: const Text('Perbarui otomatis'),
                    subtitle: const Text(
                      'Periksa jumlah notifikasi setiap 30 detik saat aplikasi aktif.',
                    ),
                    value: value.autoRefresh,
                    onChanged: _busy
                        ? null
                        : (value) => _change(autoRefresh: value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Preferensi berlaku di perangkat ini. Tarik halaman notifikasi ke bawah untuk memperbarui secara manual.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
