import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../pesanan/data/transaksi_ringkas.dart';
import '../data/home_repository.dart';
import '../data/layanan.dart';
import '../data/outlet_info.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(apiClientProvider));
});

final layananProvider = FutureProvider<List<Layanan>>((ref) {
  return ref.watch(homeRepositoryProvider).layanan();
});

final outletProvider = FutureProvider<OutletInfo>((ref) {
  return ref.watch(homeRepositoryProvider).outlet();
});

final pesananAktifProvider = FutureProvider<TransaksiRingkas?>((ref) {
  return ref.watch(homeRepositoryProvider).pesananAktif();
});
