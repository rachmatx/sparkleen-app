import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/application/auth_controller.dart';

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});
  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  bool _busy = false;
  String? _error;
  Future<void> _change(
    Future<void> Function(BiometricService, String) action,
  ) async {
    if (_busy) return;
    final revision = ref.read(customerSessionRevisionProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await ref.read(tokenStorageProvider).read();
      if (token != null) {
        await action(ref.read(biometricServiceProvider), token);
      }
    } catch (error) {
      if (mounted && revision == ref.read(customerSessionRevisionProvider)) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Pengaturan belum dapat diubah. Coba lagi.',
        );
      }
    } finally {
      if (mounted && revision == ref.read(customerSessionRevisionProvider)) {
        ref.invalidate(biometricSettingsProvider);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(biometricSettingsProvider);
    final ready = ref.watch(biometricAvailableProvider).value == true;
    final enabled = settings.value?.enabled == true;
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Keamanan akun')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Akses lebih praktis, tetap terlindungi',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Login pertama memakai PIN akun. Setelah diaktifkan, sidik jari atau biometrik perangkat bisa membuka kembali sesi yang masih berlaku. Data biometrik tetap ditangani oleh sistem perangkat.',
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Buka dengan biometrik'),
                    subtitle: Text(
                      ready
                          ? 'Sesi dikunci saat aplikasi dibuka kembali atau setelah 1 menit di latar belakang.'
                          : 'Daftarkan sidik jari di pengaturan Android agar fitur tersedia.',
                    ),
                    value: enabled,
                    onChanged: _busy || !ready || settings.isLoading
                        ? null
                        : (on) => _change(
                            (service, token) => on
                                ? service.enable(token)
                                : service.disable(token),
                          ),
                  ),
                  if (enabled)
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Konfirmasi pembayaran'),
                      subtitle: const Text(
                        'Minta biometrik sebelum membuat tagihan. Status pembayaran tetap diverifikasi server.',
                      ),
                      value: settings.value?.payments == true,
                      onChanged: _busy || !ready
                          ? null
                          : (on) => _change(
                              (service, token) =>
                                  service.paymentPreference(token, on),
                            ),
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (settings.hasError)
                    const Text(
                      'Pengaturan keamanan belum dapat dibaca. Masuk ulang dengan PIN akun.',
                    ),
                  if (_busy) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (enabled && !ready)
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => ref.read(authControllerProvider.notifier).logout(),
                child: const Text('Masuk ulang dengan PIN akun'),
              ),
            const SizedBox(height: 8),
            const Text(
              'Sesi yang kedaluwarsa tetap memerlukan PIN akun. Logout atau berganti server menghapus pengaturan biometrik sesi ini.',
            ),
          ],
        ),
      ),
    );
  }
}
