import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_value_view.dart';
import '../application/loyalty_controller.dart';
import '../data/loyalty_repository.dart';

class RedemptionPage extends ConsumerStatefulWidget {
  const RedemptionPage({super.key, required this.id});
  final int id;
  @override
  ConsumerState<RedemptionPage> createState() => _RedemptionPageState();
}

class _RedemptionPageState extends ConsumerState<RedemptionPage> {
  final _input = TextEditingController(text: '1');
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit(RedemptionQuote quote, int points) async {
    final revision = ref.read(customerSessionRevisionProvider);
    final correction = quote.correction(points);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tukar poin sekarang?'),
        content: SingleChildScrollView(
          child: Text(
            'Gunakan $points poin untuk potongan ${formatRupiah(points * quote.value)}.\n\n${correction > 0 ? 'Perolehan poin pesanan berkurang $correction poin karena total belanja turun.\n\n' : ''}Sisa tagihan: ${formatRupiah(quote.total - points * quote.value)}\nSaldo setelah penukaran: ${quote.balance - points - correction} poin\n\nPenukaran hanya sekali per pesanan dan tidak dapat dibatalkan dari aplikasi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, tukar poin'),
          ),
        ],
      ),
    );
    if (confirmed == true &&
        mounted &&
        revision == ref.read(customerSessionRevisionProvider)) {
      await ref.read(redemptionProvider(widget.id).notifier).redeem(points);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = redemptionProvider(widget.id);
    final theme = Theme.of(context);
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Tukar poin')),
        body: AsyncValueView<RedemptionView>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (context, view) {
            final quote = view.quote;
            final points = int.tryParse(_input.text) ?? 0;
            final valid = points > 0 && points <= quote.maxPoints;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Text(quote.nota, style: theme.textTheme.bodySmall),
                const SizedBox(height: 18),
                AppCard(
                  child: Column(
                    children: [
                      AppSummaryRow(
                        label: 'Saldo tersedia',
                        value: '${quote.balance} poin',
                        emphasized: true,
                      ),
                      const Divider(height: 16),
                      AppSummaryRow(
                        label: 'Tagihan pesanan',
                        value: formatRupiah(quote.total),
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1 poin = ${formatRupiah(quote.value)} potongan.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 22),
                if (quote.redemption != null)
                  AppCard(
                    color: theme.colorScheme.primaryContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Poin berhasil ditukar',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${quote.redemption!['points']} poin digunakan. Diskon ${formatRupiah((quote.redemption!['discount'] as num).toInt())} sudah masuk pada nota.',
                        ),
                      ],
                    ),
                  )
                else if (!quote.canRedeem) ...[
                  AppInfoBanner(
                    message:
                        quote.reason ??
                        'Penukaran belum tersedia untuk pesanan ini.',
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/pesanan'),
                    child: const Text('Kembali ke pesanan'),
                  ),
                ] else ...[
                  AppTextFormField(
                    controller: _input,
                    enabled: !view.busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Jumlah poin',
                      suffixText: 'poin',
                      helperText: 'Masukkan 1–${quote.maxPoints} poin.',
                      errorText: valid
                          ? null
                          : 'Masukkan 1–${quote.maxPoints} poin',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  if (valid) ...[
                    AppCard(
                      child: Column(
                        children: [
                          AppSummaryRow(
                            label: 'Potongan',
                            value: '-${formatRupiah(points * quote.value)}',
                            valueColor: theme.colorScheme.primary,
                            emphasized: true,
                          ),
                          AppSummaryRow(
                            label: 'Sisa tagihan',
                            value: formatRupiah(
                              quote.total - points * quote.value,
                            ),
                            emphasized: true,
                          ),
                          const Divider(height: 24),
                          AppSummaryRow(
                            label: 'Saldo akhir',
                            value:
                                '${quote.balance - points - quote.correction(points)} poin',
                            emphasized: true,
                          ),
                        ],
                      ),
                    ),
                    if (quote.correction(points) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: AppInfoBanner(
                          message:
                              'Termasuk penyesuaian ${quote.correction(points)} poin dari pesanan karena nilai belanja berkurang.',
                        ),
                      ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: !valid || view.busy
                        ? null
                        : () => _submit(quote, points),
                    child: Text(view.busy ? 'Memproses…' : 'Tinjau penukaran'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rincian akan dikonfirmasi sebelum poin digunakan.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (view.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      view.error is ApiException
                          ? (view.error as ApiException).message
                          : 'Penukaran belum berhasil. Periksa status pesanan sebelum mencoba lagi.',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
