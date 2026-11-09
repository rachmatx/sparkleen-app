import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;
  final String? illustrationAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AppBackdrop(
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, keyboardVisible ? 12 : 24, 16, 24),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthHeader(showBack: showBack),
                    SizedBox(height: keyboardVisible ? 20 : 28),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final showArt =
                            !keyboardVisible &&
                            illustrationAsset != null &&
                            MediaQuery.textScalerOf(context).scale(16) <= 22;
                        final intro = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: theme.textTheme.headlineLarge,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: intro),
                            if (showArt) ...[
                              const SizedBox(width: 12),
                              IllustrationPanel(
                                asset: illustrationAsset!,
                                width: 76,
                                height: 84,
                                padding: const EdgeInsets.all(4),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    AppCard(padding: const EdgeInsets.all(20), child: child),
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

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        if (showBack) ...[
          IconButton(
            tooltip: 'Kembali',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/login'),
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: colors.onSurface,
              backgroundColor: colors.surface,
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 24),
          ),
          const SizedBox(width: 12),
        ],
        const BrandMark(size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sparkleen',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Laundry',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
