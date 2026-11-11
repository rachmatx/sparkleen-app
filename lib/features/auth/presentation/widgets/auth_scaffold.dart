import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_card.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.showBack = false,
    this.illustrationAsset,
  });
  final String title, subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;
  final String? illustrationAsset;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AppBackdrop(
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, keyboard ? 12 : 24, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthBrandHeader(),
                    SizedBox(height: keyboard ? 20 : 28),
                    if (illustrationAsset != null && !keyboard) ...[
                      AppArtwork(asset: illustrationAsset!, height: 176),
                      const SizedBox(height: 20),
                    ],
                    Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.headlineLarge),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    child,
                    if (footer != null) ...[
                      const SizedBox(height: 16),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const BrandMark(size: 36),
      const SizedBox(width: 10),
      Expanded(
        child: Text('sparkleen', style: Theme.of(context).textTheme.titleLarge),
      ),
      if (ApiConfig.isPreview)
        IconButton(
          tooltip: 'Pengaturan koneksi',
          onPressed: () => context.push('/server'),
          icon: const Icon(Icons.settings_outlined),
        ),
    ],
  );
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(AppColors.radiusInput),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 24,
              color: colors.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onErrorContainer,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthLinkPrompt extends StatelessWidget {
  const AuthLinkPrompt({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onPressed,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
