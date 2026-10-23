import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_view.dart';
import '../application/pesanan_controller.dart';
import 'widgets/transaksi_card.dart';

class PesananPage extends ConsumerStatefulWidget {
  const PesananPage({super.key});

  @override
  ConsumerState<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends ConsumerState<PesananPage> {
  final _scrollController = ScrollController();
  PesananScope _scope = PesananScope.aktif;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(pesananControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() =>
      ref.read(pesananControllerProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pesananControllerProvider);
    final activeScope = async.value?.scope ?? _scope;

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<PesananScope>(
                segments: const [
                  ButtonSegment(
                    value: PesananScope.aktif,
                    label: Text('Aktif'),
                  ),
                  ButtonSegment(
                    value: PesananScope.selesai,
                    label: Text('Selesai'),
                  ),
                  ButtonSegment(
                    value: PesananScope.semua,
                    label: Text('Semua'),
                  ),
                ],
                selected: {activeScope},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  final next = selection.first;
                  if (next == activeScope) return;
                  setState(() => _scope = next);
                  ref.read(pesananControllerProvider.notifier).load(next);
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AsyncValueView<PesananState>(
                value: async,
                isEmpty: (data) => data.items.isEmpty,
                onRetry: _refresh,
                emptyBuilder: (context) => RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 24),
                      EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: _emptyMessage(activeScope),
                      ),
                    ],
                  ),
                ),
                builder: (context, data) => RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        data.items.length +
                        (data.isLoadingMore || data.error != null ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index >= data.items.length) {
                        return _LoadMoreFooter(state: data);
                      }
                      final transaksi = data.items[index];
                      return TransaksiCard(
                        transaksi: transaksi,
                        onTap: () => context.push('/pesanan/${transaksi.id}'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
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
                color: AppColors.muted,
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
