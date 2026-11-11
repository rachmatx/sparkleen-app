import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../application/pesanan_controller.dart';
import 'widgets/transaksi_card.dart';

class PesananPage extends ConsumerStatefulWidget {
  const PesananPage({super.key, this.fullHistory = false});
  final bool fullHistory;

  @override
  ConsumerState<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends ConsumerState<PesananPage> {
  final _scrollController = ScrollController();
  PesananScope _scope = PesananScope.aktif;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(pesananControllerProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pesananControllerProvider);
    final activeScope = async.value?.scope ?? _scope;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    return AppBackdrop(
      child: Scaffold(
        appBar: widget.fullHistory
            ? AppBar(title: const Text('Riwayat pesanan'))
            : null,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fullHistory ? 'Semua pesanan' : 'Pesanan',
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pantau cucian kamu dari masuk sampai siap diambil.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: AppCard(
                  padding: const EdgeInsets.all(4),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final scope in PesananScope.values)
                          SizedBox(
                            width: (constraints.maxWidth - 8) / 3,
                            child: Semantics(
                              selected: scope == activeScope,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 12,
                                  ),
                                  backgroundColor: scope == activeScope
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  foregroundColor: scope == activeScope
                                      ? Colors.white
                                      : colors.onSurfaceVariant,
                                  textStyle: textTheme.labelLarge?.copyWith(
                                    fontSize: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  if (scope == activeScope) return;
                                  setState(() => _scope = scope);
                                  ref
                                      .read(pesananControllerProvider.notifier)
                                      .load(scope);
                                  if (_scrollController.hasClients) {
                                    _scrollController.jumpTo(0);
                                  }
                                },
                                child: Text(switch (scope) {
                                  PesananScope.aktif => 'Aktif',
                                  PesananScope.selesai => 'Selesai',
                                  PesananScope.semua => 'Semua',
                                }, textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: AsyncValueView<PesananState>(
                    value: async,
                    isEmpty: (data) => data.items.isEmpty,
                    onRetry: _refresh,
                    emptyBuilder: (context) => RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 116),
                        children: [
                          const SizedBox(height: 12),
                          EmptyState(
                            icon: Icons.receipt_long_outlined,
                            illustrationAsset: activeScope == PesananScope.aktif
                                ? AppAssets.emptyActiveOrder
                                : AppAssets.emptyOrderHistory,
                            message: _emptyMessage(activeScope),
                          ),
                        ],
                      ),
                    ),
                    builder: (context, data) {
                      final items = widget.fullHistory
                          ? data.items
                          : data.items.take(20).toList();
                      final showFooter =
                          data.hasMore ||
                          (!widget.fullHistory && data.items.length > 20) ||
                          data.error != null ||
                          data.isLoadingMore;
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 4, bottom: 116),
                          itemCount: items.length + (showFooter ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index >= items.length) {
                              if (data.error != null || data.isLoadingMore) {
                                return _LoadMoreFooter(state: data);
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: OutlinedButton(
                                  onPressed: widget.fullHistory
                                      ? ref
                                            .read(
                                              pesananControllerProvider
                                                  .notifier,
                                            )
                                            .loadMore
                                      : () => context.push('/riwayat-pesanan'),
                                  child: Text(
                                    widget.fullHistory
                                        ? 'Muat 20 berikutnya'
                                        : 'Lihat semua pesanan',
                                  ),
                                ),
                              );
                            }
                            final transaksi = items[index];
                            return TransaksiCard(
                              transaksi: transaksi,
                              onTap: () =>
                                  context.push('/pesanan/${transaksi.id}'),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyMessage(PesananScope scope) {
    return switch (scope) {
      PesananScope.aktif => 'Tidak ada pesanan aktif.',
      PesananScope.selesai => 'Belum ada pesanan selesai.',
      PesananScope.semua => 'Belum ada pesanan.',
    };
  }
}

class _LoadMoreFooter extends ConsumerWidget {
  const _LoadMoreFooter({required this.state});

  final PesananState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = state.error;
    if (error != null) {
      final message = error is ApiException
          ? error.message
          : 'Gagal memuat pesanan berikutnya.';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(pesananControllerProvider.notifier).loadMore(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
