import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';

/// Decorative artwork; the adjacent heading or label supplies its meaning.
class AppArtwork extends StatelessWidget {
  const AppArtwork({
    super.key,
    required this.asset,
    required this.height,
    this.width,
    this.fallbackIcon = Icons.local_laundry_service_outlined,
  });

  final String asset;
  final double height;
  final double? width;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final decodeWidth =
        ((width ?? height * 2) * MediaQuery.devicePixelRatioOf(context))
            .ceil()
            .clamp(1, 2048)
            .toInt();

    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      cacheWidth: decodeWidth,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) => ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: Icon(
            fallbackIcon,
            size: height.clamp(20, 40).toDouble(),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) =>
      AppArtwork(asset: AppAssets.brandMark, width: size, height: size);
}

/// A pale-blue illustration surface also keeps white artwork legible in dark
/// mode. The supplied raster masters retain a little white edge matting.
class IllustrationPanel extends StatelessWidget {
  const IllustrationPanel({
    super.key,
    required this.asset,
    this.width = 164,
    this.height = 120,
    this.padding = const EdgeInsets.all(10),
    this.fallbackIcon = Icons.local_laundry_service_outlined,
  });

  final String asset;
  final double width;
  final double height;
  final EdgeInsets padding;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => AppArtwork(
        asset: asset,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        fallbackIcon: fallbackIcon,
      ),
    ),
  );
}
