import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_components.dart';
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
    final theme = Theme.of(context);
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Keamanan')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Praktis, tetap terlindungi.',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('Atur biometrik untuk perangkat ini.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Buka dengan biometrik'),
                    subtitle: Text(
                      ready ? 'Buka kembali sesi yang masih berlaku.' : 'Daftarkan sidik jari di pengaturan Android agar fitur tersedia.',
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
                  const Divider(),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Konfirmasi tagihan'),
                    subtitle: const Text(
                      'Minta biometrik sebelum membuat tagihan pembayaran.',
                    ),
                    value: settings.value?.payments == true,
                    onChanged: _busy || !ready || !enabled || settings.isLoading
                        ? null
                        : (on) => _change(
                            (service, token) =>
                                service.paymentPreference(token, on),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const AppInfoBanner(
              message: 'Sesi dikunci saat aplikasi dibuka kembali atau setelah 1 menit di latar belakang.',
            ),
            const SizedBox(height: 20),
            Text(
              'PIN akun tetap diperlukan jika sesi berakhir. Keluar akun atau berganti server akan menghapus pengaturan biometrik sesi ini.',
              style: theme.textTheme.bodySmall,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (settings.hasError)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Pengaturan keamanan belum dapat dibaca. Masuk ulang dengan PIN akun.',
                ),
              ),
            if (enabled && !ready)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => ref.read(authControllerProvider.notifier).logout(),
                child: const Text('Masuk ulang dengan PIN akun'),
              ),
            if (_busy) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
