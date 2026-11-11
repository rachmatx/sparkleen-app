/// Local artwork shared by the Sparkleen customer app.
abstract final class AppAssets {
  static const brandMark = 'assets/brand/sparkleen_mark.webp';
  static const points = 'assets/brand/badge_points.webp';
  static const home = 'assets/illustrations/splash_laundry.webp';
  static const splash = home;
  static const login = home;
  static const emptyActiveOrder =
      'assets/illustrations/empty_active_order.webp';
  static const emptyOrderHistory =
      'assets/illustrations/empty_order_history.webp';
  static const connectionError = 'assets/illustrations/error_connection.webp';
  static const cuciKering = 'assets/services/service_cuci_kering.webp';
  static const cuciSetrika = 'assets/services/service_cuci_setrika.webp';

  /// Prefer a stable API key. Legacy catalogues use a small, explicit alias
  /// list instead of assuming production IDs or guessing from substrings.
  static String? serviceArtwork({required String name, String? assetKey}) {
    if (assetKey != null && assetKey.trim().isNotEmpty) {
      return switch (assetKey.trim()) {
        'cuci_kering' || 'cuci_reguler' || 'cuci_kilat' => cuciKering,
        'cuci_setrika' => cuciSetrika,
        _ => null,
      };
    }

    final normalizedName = name.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return switch (normalizedName) {
      'cuci kering' || 'cuci reguler' || 'cuci kilat' => cuciKering,
      'cuci & setrika' ||
      'cuci + setrika' ||
      'cuci dan setrika' ||
      'cuci setrika' => cuciSetrika,
      _ => null,
    };
  }
}
