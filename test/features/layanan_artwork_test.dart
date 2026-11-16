import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/theme/app_assets.dart';
import 'package:sparkleen_mobile/features/home/data/layanan.dart';

void main() {
  test('stable artwork key survives service renaming and different IDs', () {
    final layanan = Layanan.fromJson({
      'id_layanan': 92,
      'nama_layanan': 'Perawatan Harian',
      'asset_key': 'cuci_setrika',
    });
    expect(
      AppAssets.serviceArtwork(name: layanan.nama, assetKey: layanan.assetKey),
      AppAssets.cuciSetrika,
    );
  });

  test('legacy service names accept explicit aliases and spacing', () {
    expect(
      AppAssets.serviceArtwork(name: '  CUCI   KERING '),
      AppAssets.cuciKering,
    );
    for (final alias in [
      'Cuci & Setrika',
      'Cuci dan Setrika',
      'Cuci Setrika',
    ]) {
      expect(AppAssets.serviceArtwork(name: alias), AppAssets.cuciSetrika);
    }
  });

  test('unknown services and explicit unknown keys use a generic fallback', () {
    expect(AppAssets.serviceArtwork(name: 'Cuci Sepatu'), isNull);
    expect(AppAssets.serviceArtwork(name: 'Cuci Kering Premium'), isNull);
    expect(
      AppAssets.serviceArtwork(name: 'Cuci Kering', assetKey: 'shoe_care'),
      isNull,
    );
  });
}
