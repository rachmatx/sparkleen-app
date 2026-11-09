/// Local artwork shared by the Sparkleen customer app.
abstract final class AppAssets {
  static const brandMark = 'assets/brand/sparkleen_mark.png';
  static const points = 'assets/brand/badge_points.png';
  static const home = 'assets/illustrations/home_laundry.png';
  static const login = 'assets/illustrations/auth_laundry.png';
  static const emptyActiveOrder = 'assets/illustrations/empty_active_order.png';
  static const emptyOrderHistory =
      'assets/illustrations/empty_order_history.png';
  static const connectionError = 'assets/illustrations/error_connection.png';
  static const cuciKering = 'assets/services/service_cuci_kering.png';
  static const cuciSetrika = 'assets/services/service_cuci_setrika.png';

  /// Prefer a stable API key. Legacy catalogues use a small, explicit alias
  /// list instead of assuming production IDs or guessing from substrings.
  static String? serviceArtwork({required String name, String? assetKey}) {
    if (assetKey != null && assetKey.trim().isNotEmpty) {
      return switch (assetKey.trim()) {
        'cuci_kering' => cuciKering,
        'cuci_setrika' => cuciSetrika,
        _ => null,
      };
    }

    final normalizedName = name.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return switch (normalizedName) {
      'cuci kering' => cuciKering,
      'cuci & setrika' || 'cuci dan setrika' || 'cuci setrika' => cuciSetrika,
      _ => null,
    };
  }
}
