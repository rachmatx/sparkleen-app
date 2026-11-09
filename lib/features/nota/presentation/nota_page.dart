import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_artwork.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../pesanan/application/pesanan_controller.dart';
import '../../pesanan/data/transaksi_detail.dart';
import '../data/nota_data.dart';

final notaProvider = FutureProvider.autoDispose.family<NotaData, int>((
  ref,
  id,
) {
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
        appBar: AppBar(title: const Text('Nota Digital')),
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
    final lunas = nota.statusPembayaran == 'lunas';
    final metode = nota.metode;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandMark(size: 56)),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Sparkleen',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (nota.outlet.nama.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                nota.outlet.nama,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
          if (nota.outlet.alamat.isNotEmpty)
            Center(
              child: Text(
                nota.outlet.alamat,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (nota.outlet.noWa.isNotEmpty)
            Center(
              child: Text(nota.outlet.noWa, style: theme.textTheme.bodySmall),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: TicketDivider(),
          ),
          _NotaRow(label: 'No. Nota', value: nota.noNota),
          const SizedBox(height: 6),
          _NotaRow(label: 'Tanggal', value: formatTanggal(nota.tanggal)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: TicketDivider(),
          ),
          if (nota.items.isEmpty)
            Text('Tidak ada rincian layanan.', style: theme.textTheme.bodySmall)
          else
            for (var index = 0; index < nota.items.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              _NotaItem(item: nota.items[index]),
            ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: TicketDivider(),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              children: [
                _AmountRow(
                  label: 'Subtotal',
                  value: formatRupiah(nota.subtotal),
                ),
                if (nota.diskon > 0)
                  _AmountRow(
                    label: 'Diskon',
                    value: '-${formatRupiah(nota.diskon)}',
                    color: colors.primary,
                  ),
                const SizedBox(height: 4),
                _AmountRow(
                  label: 'Grand total',
                  value: formatRupiah(nota.grandTotal),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Pembayaran',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lunas ? 'Lunas' : 'Belum dibayar',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    if (metode != null && metode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metode,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Terima kasih',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Terima kasih telah menggunakan Sparkleen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotaRow extends StatelessWidget {
  const _NotaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotaItem extends StatelessWidget {
  const _NotaItem({required this.item});

  final TransaksiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.namaLayanan,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatBerat(item.berat)} × ${formatRupiah(item.hargaSatuan)}/kg',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            formatRupiah(item.subtotal),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle =
        (bold ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)
            ?.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? colors.onSurface : colors.onSurfaceVariant,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style:
                  (bold
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.bodySmall)
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            color ?? (bold ? colors.primary : colors.onSurface),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
