import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/activate_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/splash/splash_page.dart';
import 'placeholder_page.dart';

const _authRoutes = {'/login', '/register', '/activate'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AsyncValue<AuthState>>(
    const AsyncLoading<AuthState>(),
  );

  ref.listen<AsyncValue<AuthState>>(
    authControllerProvider,
    (_, next) => refresh.value = next,
    fireImmediately: true,
  );

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/activate',
        builder: (context, state) => const ActivatePage(),
      ),
      GoRoute(
        path: '/beranda',
        builder: (context, state) => const PlaceholderPage(
          title: 'Beranda',
          icon: Icons.home_rounded,
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });

  return router;
});

String? _redirect(Ref ref, String location) {
  final auth = ref.read(authControllerProvider);
  final isAuthRoute = _authRoutes.contains(location);
  final isSplash = location == '/splash';

  if (auth.isLoading) return null;

  if (auth.hasError) {
    return isSplash ? '/login' : null;
  }

  final value = auth.value;

  if (value is AuthAuthenticated) {
    return isAuthRoute || isSplash ? '/beranda' : null;
  }

  if (value is AuthUnauthenticated) {
    return isAuthRoute ? null : '/login';
  }

  return isAuthRoute ? null : '/splash';
}
