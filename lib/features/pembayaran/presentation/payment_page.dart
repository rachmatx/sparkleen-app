import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/biometric_service.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../application/payment_controller.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.id});
  final int id;
  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage>
    with WidgetsBindingObserver {
  Timer? _poll;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _syncActive());
  }

  void _syncActive() {
    if (!mounted || !_foreground) return;
    final value = ref.read(paymentControllerProvider(widget.id)).value;
    if (value != null && value.snapshot.active && !value.busy) {
      unawaited(ref.read(paymentControllerProvider(widget.id).notifier).sync());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _syncActive();
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan tagihan?'),
        content: const Text(
          'Tagihan hanya dibatalkan setelah gateway mengonfirmasi. Pesanan cucian tetap berjalan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan tagihan'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(paymentControllerProvider(widget.id).notifier).cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = paymentControllerProvider(widget.id);
    final colors = Theme.of(context).colorScheme;
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Pembayaran')),
        body: AsyncValueView<PaymentViewState>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (context, view) {
            final payment = view.snapshot;
            final actions = ref.read(provider.notifier);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        payment.status == 'SUCCESS'
                            ? Icons.verified_outlined
                            : Icons.receipt_long_outlined,
                        color: colors.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        payment.status == 'SUCCESS'
                            ? 'Pembayaran tercatat'
                            : 'Sisa tagihan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatRupiah(
                          payment.status == 'SUCCESS'
                              ? payment.amount
                              : payment.remaining,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        payment.status == 'SUCCESS'
                            ? 'Pesanan sudah lunas. Bukti pembayaran tersedia pada nota pesanan.'
                            : 'Nominal mengikuti catatan pembayaran outlet.',
                      ),
                    ],
                  ),
                ),
                if (payment.status == 'SUCCESS') ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/pesanan/${widget.id}/nota'),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Lihat nota'),
                  ),
                  TextButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/pesanan'),
                    child: const Text('Kembali ke pesanan'),
                  ),
                ],
                const SizedBox(height: 16),
                AppCard(
                  color: colors.primaryContainer,
                  child: Text(
                    'Mode simulasi • Untuk uji coba Sparkleen dan Smart Pay. QR dan rekening di halaman ini bukan sarana pembayaran bank. Jangan transfer uang nyata.',
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: view.busy ? null : () => context.push('/keamanan'),
                  icon: const Icon(Icons.fingerprint),
                  label: Text(
                    ref.watch(biometricSettingsProvider).value?.payments == true
                        ? 'Konfirmasi biometrik aktif'
                        : 'Atur keamanan pembayaran',
                  ),
                ),
                if (view.error != null) ...[
                  AppCard(
                    color: colors.errorContainer,
                    child: Text(
                      view.error is ApiException
                          ? (view.error as ApiException).message
                          : 'Status belum dapat diperiksa. Coba lagi; tagihan tetap tersimpan.',
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (payment.status == 'NONE') ...[
                  if (!payment.enabled)
                    const AppCard(
                      child: Text(
                        'Pembayaran dari aplikasi belum diaktifkan outlet. Silakan bayar melalui kasir.',
                      ),
                    )
                  else
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pilih metode simulasi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: view.busy
                                ? null
                                : () => actions.start('QRIS'),
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('Buat QR simulasi'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: view.busy
                                ? null
                                : () => actions.start('TRANSFER'),
                            icon: const Icon(Icons.account_balance_outlined),
                            label: const Text('Transfer simulasi'),
                          ),
                        ],
                      ),
                    ),
                ] else if (payment.active) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(switch (payment.status) {
                          'PROCESSING' => 'Tagihan sedang disiapkan',
                          'EXPIRED' => 'Waktu tagihan habis',
                          _ => 'Menunggu pembayaran simulasi',
                        }, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Text(switch (payment.status) {
                          'PROCESSING' => 'Periksa status untuk melanjutkan tagihan yang sama. Anda tidak perlu membuat tagihan baru.',
                          'EXPIRED' => 'Periksa status agar gateway mengonfirmasi kedaluwarsa sebelum membuat tagihan berikutnya.',
                          _ => 'Gunakan Smart Pay untuk menguji tagihan ini. Status diperiksa otomatis selama halaman terbuka.',
                        }),
                        if (payment.expiresAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Batas waktu: ${formatTanggal(payment.expiresAt!)}',
                            ),
                          ),
                        if (payment.status == 'PENDING') ...[
                          const SizedBox(height: 20),
                          if (payment.method == 'QRIS')
                            _DemoQr(
                              data: payment.detail['qr_image']?.toString(),
                            )
                          else ...[
                            const Text(
                              'BANK SIMULASI',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Rekening dummy • tidak menerima transfer uang',
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Text('Kode simulasi Smart Pay'),
                          const SizedBox(height: 6),
                          SelectableText(
                            payment.detail['simulation_code']?.toString() ??
                                'Kode belum tersedia',
                          ),
                          TextButton.icon(
                            onPressed:
                                payment.detail['simulation_code'] is String
                                ? () async {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text:
                                            payment.detail['simulation_code']
                                                as String,
                                      ),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Kode simulasi disalin',
                                              ),
                                            ),
                                          );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.copy_outlined),
                            label: const Text('Salin kode simulasi'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: view.busy ? null : actions.sync,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Periksa status'),
                        ),
                        TextButton(
                          onPressed: view.busy ? null : _cancel,
                          child: const Text('Batalkan tagihan'),
                        ),
                      ],
                    ),
                  ),
                ] else if (payment.status == 'REVIEW')
                  const AppCard(
                    child: Text(
                      'Tagihan perlu diperiksa outlet. Hubungi kasir sebelum melanjutkan pembayaran.',
                    ),
                  ),
                if (view.busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DemoQr extends StatelessWidget {
  const _DemoQr({this.data});
  final String? data;
  @override
  Widget build(BuildContext context) {
    try {
      if (data == null ||
          !data!.startsWith('data:image/png;base64,') ||
          data!.length > 100000) {
        throw const FormatException();
      }
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 264),
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.memory(
                base64Decode(data!.substring(22)),
                semanticLabel: 'QR simulasi Smart Pay',
                errorBuilder: (_, _, _) => const Text(
                  'QR belum tersedia. Gunakan kode simulasi.',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      );
    } on FormatException {
      return const Text('QR belum tersedia. Gunakan kode simulasi di bawah.');
    }
  }
}
