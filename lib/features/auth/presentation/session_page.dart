import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_config.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_artwork.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/settings/server_settings.dart';
import 'widgets/auth_scaffold.dart';
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
    final theme = Theme.of(context);
    final local = ref.watch(serverAddressProvider).startsWith('http://');
    if (!locked) {
      return AppBackdrop(
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthBrandHeader(),
                  const SizedBox(height: 26),
                  const AppArtwork(
                    asset: AppAssets.connectionError,
                    height: 166,
                    width: 230,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Koneksi belum\ntersambung.',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kami belum bisa memeriksa sesimu. Periksa internet atau alamat server, lalu coba lagi.',
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Row(
                      children: [
                        Icon(
                          local ? Icons.dns_outlined : Icons.public_rounded,
                          size: 34,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                local ? 'Server lokal' : 'Server online',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                local
                                    ? 'Pastikan HP dan laptop pada Wi-Fi yang sama.'
                                    : 'Pastikan perangkat terhubung ke internet dan server dapat diakses.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy || value.isLoading
                        ? null
                        : () => _run(controller.retrySession),
                    child: Text(_busy ? 'Memeriksa…' : 'Coba lagi'),
                  ),
                  if (ApiConfig.isPreview)
                    TextButton(
                      onPressed: _busy ? null : () => context.push('/server'),
                      child: const Text('Periksa alamat server pengujian'),
                    ),
                  const Divider(height: 24),
                  TextButton(
                    onPressed: _busy ? null : () => _run(controller.logout),
                    child: const Text('Masuk ulang dengan PIN akun'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return AppBackdrop(
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthBrandHeader(),
                          if (locked) ...[
                            const SizedBox(height: 24),
                            AppCard(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    foregroundColor:
                                        theme.colorScheme.onPrimaryContainer,
                                    child: const Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Akun tersimpan',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Buka untuk melanjutkan.'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            if (!locked) ...[
                              const AppArtwork(
                                asset: AppAssets.connectionError,
                                height: 120,
                              ),
                              const SizedBox(height: 20),
                            ],
                            Text(
                              locked
                                  ? 'Selamat datang kembali'
                                  : 'Koneksi belum tersambung.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              locked
                                  ? 'Buka Sparkleen dengan biometrik perangkatmu.'
                                  : 'Sesi Anda tetap tersimpan. Periksa koneksi atau alamat server, lalu coba lagi.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          FilledButton.icon(
                            onPressed: _busy || value.isLoading
                                ? null
                                : () => _run(
                                    locked
                                        ? controller.unlock
                                        : controller.retrySession,
                                  ),
                            icon: Icon(
                              locked ? Icons.fingerprint : Icons.refresh,
                              size: 24,
                            ),
                            label: Text(
                              locked ? 'Buka dengan biometrik' : 'Coba lagi',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _run(controller.logout),
                            child: const Text('Masuk ulang dengan PIN akun'),
                          ),
                          if (ApiConfig.isPreview)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => context.push('/server'),
                              child: const Text(
                                'Periksa alamat server pengujian',
                              ),
                            ),
                          if (_busy || value.isLoading)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
