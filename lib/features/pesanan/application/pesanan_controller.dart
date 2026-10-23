import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/transaksi_repository.dart';
import '../data/transaksi_ringkas.dart';

enum PesananScope {
  aktif('aktif'),
  selesai('selesai'),
  semua('semua');

  const PesananScope(this.apiValue);

  final String apiValue;
}

class PesananState {
  const PesananState({
    this.items = const [],
    this.page = 1,
    this.lastPage = 1,
    this.scope = PesananScope.aktif,
    this.isLoadingMore = false,
    this.error,
  });

  final List<TransaksiRingkas> items;
  final int page;
  final int lastPage;
  final PesananScope scope;
  final bool isLoadingMore;
  final Object? error;

  bool get hasMore => page < lastPage;

  PesananState copyWith({
    List<TransaksiRingkas>? items,
    int? page,
    int? lastPage,
    PesananScope? scope,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return PesananState(
      items: items ?? this.items,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      scope: scope ?? this.scope,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final transaksiRepositoryProvider = Provider<TransaksiRepository>(
  (ref) => TransaksiRepository(ref.watch(apiClientProvider)),
);

final pesananControllerProvider =
    AsyncNotifierProvider<PesananController, PesananState>(
      PesananController.new,
    );

class PesananController extends AsyncNotifier<PesananState> {
  TransaksiRepository get _repository => ref.read(transaksiRepositoryProvider);

  @override
  Future<PesananState> build() => _fetch(PesananScope.aktif, page: 1);

  Future<PesananState> _fetch(
    PesananScope scope, {
    required int page,
  }) async {
    final result = await _repository.list(
      status: scope.apiValue,
      page: page,
      perPage: 20,
    );
    return PesananState(
      items: result.items,
      page: result.page,
      lastPage: result.lastPage,
      scope: scope,
      isLoadingMore: false,
      error: null,
    );
  }

  Future<void> load(PesananScope scope) async {
    state = const AsyncLoading<PesananState>();
    state = await AsyncValue.guard(() => _fetch(scope, page: 1));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearError: true),
    );

    try {
      final result = await _repository.list(
        status: current.scope.apiValue,
        page: current.page + 1,
        perPage: 20,
      );
      if (!ref.mounted) return;

      final latest = state.value ?? current;
      final seen = latest.items.map((item) => item.id).toSet();
      final merged = [
        ...latest.items,
        ...result.items.where((item) => seen.add(item.id)),
      ];
      state = AsyncData(
        latest.copyWith(
          items: merged,
          page: result.page,
          lastPage: result.lastPage,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = AsyncData(
        (state.value ?? current).copyWith(
          isLoadingMore: false,
          error: error,
        ),
      );
    }
  }

  Future<void> refresh() async {
    final scope = state.value?.scope ?? PesananScope.aktif;
    state = await AsyncValue.guard(() => _fetch(scope, page: 1));
  }
}
