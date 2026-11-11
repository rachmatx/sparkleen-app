import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../sync/customer_refresh.dart';
import 'biometric_service.dart';

final sessionClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class SessionBoundary extends ConsumerStatefulWidget {
  const SessionBoundary({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<SessionBoundary> createState() => _SessionBoundaryState();
}

class _SessionBoundaryState extends ConsumerState<SessionBoundary>
    with WidgetsBindingObserver {
  DateTime? _backgroundAt;
  bool _obscured = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final secured = ref.read(biometricSettingsProvider).value?.enabled == true;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (secured && mounted) setState(() => _obscured = true);
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundAt ??= ref.read(sessionClockProvider)();
    }
    if (state == AppLifecycleState.resumed) {
      final since = _backgroundAt;
      _backgroundAt = null;
      if (secured &&
          since != null &&
          ref.read(sessionClockProvider)().difference(since) >=
              const Duration(minutes: 1)) {
        ref.read(authControllerProvider.notifier).lock();
      }
      if (mounted) setState(() => _obscured = false);
      if (since != null &&
          ref.read(authControllerProvider).value is AuthAuthenticated) {
        ref.read(customerRefreshProvider.notifier).refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(biometricSettingsProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_obscured)
          ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Icon(
                Icons.lock_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
