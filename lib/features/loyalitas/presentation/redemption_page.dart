import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
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
    final colors = Theme.of(context).colorScheme;
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(quote.nota, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo ${quote.balance} poin',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Tagihan ${formatRupiah(quote.total)}'),
                      const SizedBox(height: 8),
                      Text('1 poin = ${formatRupiah(quote.value)} potongan.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (quote.redemption != null)
                  AppCard(
                    color: colors.primaryContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          color: colors.onPrimaryContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Poin berhasil ditukar',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.onPrimaryContainer),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${quote.redemption!['points']} poin digunakan. Diskon ${formatRupiah((quote.redemption!['discount'] as num).toInt())} sudah masuk pada nota.',
                          style: TextStyle(color: colors.onPrimaryContainer),
                        ),
                      ],
                    ),
                  )
                else if (!quote.canRedeem)
                  AppCard(
                    child: Text(
                      quote.reason ??
                          'Penukaran belum tersedia untuk pesanan ini.',
                    ),
                  )
                else
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Gunakan poin untuk pesanan ini',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _input,
                          enabled: !view.busy,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(7),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Jumlah poin',
                            helperText: 'Maksimal ${quote.maxPoints} poin',
                            errorText: valid
                                ? null
                                : 'Masukkan 1–${quote.maxPoints} poin',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        if (valid) ...[
                          Text(
                            'Potongan: ${formatRupiah(points * quote.value)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sisa tagihan: ${formatRupiah(quote.total - points * quote.value)}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Saldo akhir: ${quote.balance - points - quote.correction(points)} poin',
                          ),
                          if (quote.correction(points) > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Perolehan poin pesanan disesuaikan turun ${quote.correction(points)} poin karena nilai belanja berkurang.',
                              ),
                            ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: view.busy || !valid
                              ? null
                              : () => _submit(quote, points),
                          child: const Text('Tinjau penukaran'),
                        ),
                      ],
                    ),
                  ),
                if (view.error != null) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    color: colors.errorContainer,
                    child: Text(
                      view.error is ApiException
                          ? (view.error as ApiException).message
                          : 'Penukaran belum dapat dipastikan. Coba lagi untuk memeriksa permintaan yang sama.',
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                  TextButton(
                    onPressed: view.busy
                        ? null
                        : () => ref.invalidate(provider),
                    child: const Text('Muat ulang rincian'),
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
