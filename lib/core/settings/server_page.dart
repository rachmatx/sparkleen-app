import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../providers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_components.dart';
import '../widgets/app_text_field.dart';
import '../app_info.dart';
import 'server_settings.dart';

class ServerPage extends ConsumerStatefulWidget {
  const ServerPage({super.key});
  @override
  ConsumerState<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends ConsumerState<ServerPage> {
  late final _address = TextEditingController(
    text: ref.read(serverAddressProvider),
  );
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    String value;
    try {
      value = validateServerAddress(_address.text);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti server pengujian?'),
        content: const Text(
          'Sesi pada server sebelumnya akan dihapus dari HP. Login hanya ke server yang Anda percayai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan server'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).logout();
      await ref.read(tokenStorageProvider).clear();
      await const ServerSettings().save(value);
      if (!mounted) return;
      ref.read(serverAddressProvider.notifier).change(value);
      ref.read(customerSessionRevisionProvider.notifier).advance();
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() => _error = 'Alamat belum tersimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = ref.watch(serverAddressProvider);
    final local = Uri.tryParse(address)?.scheme == 'http';
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Konfigurasi server')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.dns_outlined,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Server aktif',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          address,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          local ? 'Lokal' : 'HTTPS',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Hubungkan Sparkleen', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Gunakan alamat server online atau IP laptopmu.'),
            const SizedBox(height: 24),
            AppTextFormField(
              controller: _address,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Alamat server',
                hintText: 'http://192.168.1.10:8080',
                errorText: _error,
                helperText: 'Tanpa /api/v1 di akhir alamat.',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Lokal: HTTP, HP dan laptop pada Wi-Fi yang sama.\nOnline: gunakan HTTPS.\nAlamat 10.0.2.2 hanya untuk emulator.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            const AppInfoBanner(
              message: 'Mengganti server akan mengakhiri sesi pada server sebelumnya.',
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Simpan dan masuk'),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 24),
            Text(
              'Sparkleen ${AppInfo.versionLabel} · Pratinjau pengujian',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
