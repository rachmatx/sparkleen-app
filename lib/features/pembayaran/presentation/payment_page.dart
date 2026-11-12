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
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/status_chip.dart';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Pembayaran')),
        body: AsyncValueView<PaymentViewState>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (context, view) {
            final payment = view.snapshot;
            final actions = ref.read(provider.notifier);
            final paid = payment.status == 'SUCCESS';
            final pending = const [
              'PENDING',
              'PROCESSING',
              'EXPIRED',
            ].contains(payment.status);
            final code = payment.detail['simulation_code'];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (paid) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: .75),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 46,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Pembayaran tercatat',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pesananmu sudah lunas.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    formatRupiah(payment.displayAmount),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      children: [
                        AppSummaryRow(label: 'Pesanan', value: '#${widget.id}'),
                        const Divider(height: 16),
                        if (payment.method != null) ...[
                          AppSummaryRow(
                            label: 'Metode',
                            value: '${payment.method} simulasi',
                          ),
                          const Divider(height: 16),
                        ],
                        AppSummaryRow(
                          label: 'Status',
                          value: 'Lunas',
                          valueColor: statusColor(
                            'lunas',
                            brightness: theme.brightness,
                          ),
                        ),
                        const Divider(height: 16),
                        const AppSummaryRow(
                          label: 'Bukti pembayaran',
                          value: 'Tersimpan pada nota',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    spacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sisa tagihan',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatRupiah(payment.displayAmount),
                            style: theme.textTheme.headlineLarge,
                          ),
                        ],
                      ),
                      if (pending)
                        const StatusChip(
                          status: 'menunggu',
                          label: 'Menunggu pembayaran',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                const AppInfoBanner(
                  message: 'Mode simulasi · Untuk pengujian Smart Pay. Jangan transfer uang nyata.',
                ),
                const SizedBox(height: 16),
                if (view.error != null) ...[
                  AppInfoBanner(
                    message: view.error is ApiException
                        ? (view.error as ApiException).message
                        : 'Status belum dapat diperiksa. Coba lagi; tagihan tetap tersimpan.',
                  ),
                  const SizedBox(height: 12),
                ],
                if (paid) ...[
                  FilledButton(
                    onPressed: () => context.push('/pesanan/${widget.id}/nota'),
                    child: const Text('Lihat nota'),
                  ),
                  TextButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/pesanan'),
                    child: const Text('Kembali ke pesanan'),
                  ),
                ] else if (payment.status == 'NONE') ...[
                  if (!payment.enabled)
                    const AppInfoBanner(
                      message: 'Pembayaran dari aplikasi belum diaktifkan outlet. Silakan bayar melalui kasir.',
                    )
                  else
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pilih metode simulasi',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: view.busy
                                ? null
                                : () => actions.start('QRIS'),
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('Buat QR simulasi'),
                          ),
                          const SizedBox(height: 10),
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
                ] else if (pending) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Icon(
                            payment.method == 'QRIS'
                                ? Icons.qr_code_scanner_rounded
                                : Icons.account_balance_outlined,
                            size: 27,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          payment.status == 'PROCESSING'
                              ? 'Tagihan sedang disiapkan'
                              : payment.status == 'EXPIRED'
                              ? 'Tagihan melewati batas waktu'
                              : payment.method == 'QRIS'
                              ? 'QR simulasi Smart Pay'
                              : 'Transfer simulasi Smart Pay',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (payment.status == 'PENDING') ...[
                          if (payment.method == 'QRIS')
                            _DemoQr(
                              data: payment.detail['qr_image']?.toString(),
                            )
                          else ...[
                            const Text(
                              'BANK SIMULASI',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Rekening dummy • tidak menerima transfer uang',
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (payment.expiresAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Berlaku hingga ${formatTanggal(payment.expiresAt!)} WIB',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          const Divider(height: 28),
                          const Text('Kode simulasi Smart Pay'),
                          const SizedBox(height: 6),
                          SelectableText(
                            code?.toString() ?? 'Kode belum tersedia',
                            style: theme.textTheme.titleSmall,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: code is String
                                  ? () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: code),
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
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              label: const Text('Salin kode simulasi'),
                            ),
                          ),
                        ] else
                          Text(
                            payment.status == 'PROCESSING'
                                ? 'Periksa status untuk melanjutkan tagihan yang sama. Anda tidak perlu membuat tagihan baru.'
                                : 'Periksa status agar gateway mengonfirmasi kedaluwarsa sebelum membuat tagihan berikutnya.',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: view.busy ? null : actions.sync,
                    child: const Text('Periksa status'),
                  ),
                  TextButton(
                    onPressed: view.busy ? null : _cancel,
                    style: TextButton.styleFrom(foregroundColor: colors.error),
                    child: const Text('Batalkan tagihan'),
                  ),
                ] else if (payment.status == 'REVIEW')
                  const AppInfoBanner(
                    message: 'Tagihan perlu diperiksa outlet. Hubungi kasir sebelum melanjutkan pembayaran.',
                  ),
                if (!paid) ...[
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: TextButton.icon(
                      onPressed: view.busy
                          ? null
                          : () => context.push('/keamanan'),
                      icon: const Icon(Icons.fingerprint, size: 24),
                      label: Text(
                        ref.watch(biometricSettingsProvider).value?.payments ==
                                true
                            ? 'Konfirmasi biometrik aktif'
                            : 'Atur keamanan pembayaran',
                      ),
                    ),
                  ),
                ],
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
          constraints: const BoxConstraints(maxWidth: 236),
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
