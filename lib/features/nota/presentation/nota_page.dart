import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/app_artwork.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../pesanan/application/pesanan_controller.dart';
import '../data/nota_data.dart';

final notaProvider = FutureProvider.autoDispose.family<NotaData, int>((
  ref,
  id,
) {
  ref.watch(customerSessionRevisionProvider);
  return ref.watch(transaksiRepositoryProvider).nota(id);
});

class NotaPage extends ConsumerWidget {
  const NotaPage({super.key, required this.id});

  final int id;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(notaProvider(id));
    try {
      await ref.read(notaProvider(id).future);
    } on Object {
      // Error sudah ditampilkan oleh AsyncValueView.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notaProvider(id));

    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Nota digital')),
        body: AsyncValueView<NotaData>(
          value: async,
          onRetry: () => ref.invalidate(notaProvider(id)),
          loadingBuilder: (context) => const Padding(
            padding: EdgeInsets.all(20),
            child: LoadingList(itemCount: 2, itemHeight: 160),
          ),
          builder: (context, nota) => RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [_NotaReceipt(nota: nota)],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotaReceipt extends StatelessWidget {
  const _NotaReceipt({required this.nota});
  final NotaData nota;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final paid = nota.statusPembayaran == 'lunas';
    Widget rule() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: TicketDivider(),
    );
    Widget amount(String label, String value, {bool total = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: total
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: total
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        ClipPath(
          clipper: _TicketClipper(),
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BrandMark(size: 42),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'sparkleen',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              letterSpacing: -.8,
                            ),
                          ),
                          Text(
                            nota.outlet.nama.isEmpty
                                ? 'Laundry & Dry Clean'
                                : nota.outlet.nama,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (nota.outlet.alamat.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      nota.outlet.alamat,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                rule(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nota.noNota, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 3),
                        Text(
                          formatTanggal(nota.tanggal),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    StatusChip(
                      status: paid ? 'lunas' : 'belum',
                      label: paid ? 'Lunas' : 'Belum dibayar',
                    ),
                  ],
                ),
                rule(),
                for (final item in nota.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaLayanan,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${formatBerat(item.berat)} × ${formatRupiah(item.hargaSatuan)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            formatRupiah(item.subtotal),
                            textAlign: TextAlign.right,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                rule(),
                amount('Subtotal', formatRupiah(nota.subtotal)),
                amount('Diskon', formatRupiah(nota.diskon)),
                rule(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: .75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: amount(
                    'Total',
                    formatRupiah(nota.grandTotal),
                    total: true,
                  ),
                ),
                rule(),
                amount(
                  'Metode',
                  nota.metode?.isNotEmpty == true
                      ? nota.metode!
                      : 'Belum tercatat',
                ),
                if (paid) amount('Dibayar', formatRupiah(nota.grandTotal)),
                rule(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      paid
                          ? Icons.check_circle_rounded
                          : Icons.schedule_outlined,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        paid ? 'Pembayaran tercatat' : 'Menunggu pembayaran',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                rule(),
                Text(
                  'Terima kasih',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Terima kasih sudah mempercayakan cucianmu.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Nota tersimpan pada detail pesanan.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );
    for (final y in [110.0, size.height - 96]) {
      path.addOval(Rect.fromCircle(center: Offset(0, y), radius: 8));
      path.addOval(Rect.fromCircle(center: Offset(size.width, y), radius: 8));
    }
    return path;
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) => false;
}
