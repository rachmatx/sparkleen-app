import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../providers.dart';
import '../widgets/app_card.dart';
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
  Widget build(BuildContext context) => AppBackdrop(
    child: Scaffold(
      appBar: AppBar(title: const Text('Konfigurasi server')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hubungkan ke laptop',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gunakan Wi-Fi yang sama pada HP dan laptop. Isi IP Wi-Fi laptop beserta port backend, tanpa /api/v1. Alamat 10.0.2.2 hanya untuk emulator.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _address,
                  enabled: !_busy,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Alamat server',
                    hintText: 'http://192.168.1.10:8080',
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('Simpan dan masuk'),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sparkleen 0.0.1 • Pratinjau pengujian\nBackend harus sudah memuat migrasi serta API pelanggan terbaru. Pembayaran online masih simulasi.',
          ),
        ],
      ),
    ),
  );
}
