import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_config.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_artwork.dart';
import '../application/auth_controller.dart';

class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key});
  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  bool _busy = false;
  String? _error;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Sesi belum dapat dibuka. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(authControllerProvider);
    final locked = value.value is AuthLocked;
    final controller = ref.read(authControllerProvider.notifier);
    return AppBackdrop(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 64)),
                    const SizedBox(height: 24),
                    Icon(
                      locked ? Icons.fingerprint : Icons.cloud_off_outlined,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      locked
                          ? 'Selamat datang kembali'
                          : 'Sesi Anda tetap tersimpan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      locked
                          ? 'Gunakan biometrik perangkat untuk membuka Sparkleen.'
                          : 'Profil belum dapat diperiksa. Pastikan server dan koneksi tersedia, lalu coba lagi.',
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy || value.isLoading
                          ? null
                          : () => _run(
                              locked
                                  ? controller.unlock
                                  : controller.retrySession,
                            ),
                      icon: Icon(locked ? Icons.fingerprint : Icons.refresh),
                      label: Text(
                        locked ? 'Buka dengan biometrik' : 'Coba lagi',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _run(controller.logout),
                      child: const Text('Masuk ulang dengan PIN akun'),
                    ),
                    if (ApiConfig.isPreview)
                      TextButton(
                        onPressed: _busy ? null : () => context.push('/server'),
                        child: const Text('Periksa alamat server pengujian'),
                      ),
                    if (_busy || value.isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
