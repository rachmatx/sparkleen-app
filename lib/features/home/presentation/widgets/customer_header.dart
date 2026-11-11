import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../notifikasi/presentation/notification_page.dart';

class CustomerHeader extends ConsumerWidget {
  const CustomerHeader({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).value;
    final points = auth is AuthAuthenticated ? auth.pelanggan.poin : 0;
    final theme = Theme.of(context);
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(size: 34),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'sparkleen',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
        ),
      ],
    );
    final balance = AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: () => context.push('/poin'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppArtwork(asset: AppAssets.points, height: 17, width: 17),
          const SizedBox(width: 5),
          Text(
            '$points poin',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: brand),
              const NotificationBell(),
            ],
          ),
          Align(alignment: Alignment.centerRight, child: balance),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: brand),
        balance,
        const SizedBox(width: 4),
        const NotificationBell(),
      ],
    );
  }
}
