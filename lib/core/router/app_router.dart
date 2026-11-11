import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/activate_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/jemput/presentation/pickup_page.dart';
import '../../features/jemput/presentation/pickup_form_page.dart';
import '../../features/nota/presentation/nota_page.dart';
import '../../features/notifikasi/presentation/notification_page.dart';
import '../../features/loyalitas/presentation/loyalty_page.dart';
import '../../features/loyalitas/presentation/redemption_page.dart';
import '../../features/pembayaran/presentation/payment_page.dart';
import '../../features/pesanan/presentation/detail_pesanan_page.dart';
import '../../features/pesanan/presentation/pesanan_page.dart';
import '../../features/profil/presentation/profil_page.dart';
import '../../features/profil/presentation/edit_profil_page.dart';
import '../../features/splash/splash_page.dart';
import '../widgets/app_shell.dart';
import '../../features/pengaturan/presentation/settings_page.dart';
import '../api/api_config.dart';
import '../settings/server_page.dart';
import '../../features/auth/presentation/session_page.dart';
import '../../features/profil/presentation/security_page.dart';

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
        path: '/session',
        builder: (context, state) => const SessionPage(),
      ),
      GoRoute(
        path: '/keamanan',
        builder: (context, state) => const SecurityPage(),
      ),
      if (ApiConfig.isPreview)
        GoRoute(
          path: '/server',
          builder: (context, state) => const ServerPage(),
        ),
      GoRoute(
        path: '/riwayat-pesanan',
        builder: (context, state) => const PesananPage(fullHistory: true),
      ),
      GoRoute(
        path: '/ubah-profil',
        builder: (context, state) => const EditProfilPage(),
      ),
      GoRoute(
        path: '/pengaturan',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/activate',
        builder: (context, state) => const ActivatePage(),
      ),
      GoRoute(
        path: '/pesanan/:id',
        builder: (context, state) => DetailPesananPage(
          id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/pesanan/:id/nota',
        builder: (context, state) =>
            NotaPage(id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(
        path: '/pesanan/:id/pembayaran',
        builder: (context, state) => PaymentPage(
          id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/notifikasi',
        builder: (context, state) => const NotificationPage(),
      ),
      GoRoute(path: '/poin', builder: (context, state) => const LoyaltyPage()),
      GoRoute(
        path: '/pesanan/:id/poin',
        builder: (context, state) => RedemptionPage(
          id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/jemput', builder: (context, state) => const PickupPage()),
      GoRoute(
        path: '/jemput/baru',
        builder: (context, state) => const PickupFormPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beranda',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pesanan',
                builder: (context, state) => const PesananPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                builder: (context, state) => const ProfilPage(),
              ),
            ],
          ),
        ],
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

  if (ApiConfig.isPreview && location == '/server') return null;
  if (auth.isLoading) return null;

  if (auth.hasError) {
    return isSplash ? '/login' : null;
  }

  final value = auth.value;

  if (value is AuthLocked || value is AuthSessionUnavailable) {
    return location == '/session' ? null : '/session';
  }

  if (value is AuthAuthenticated) {
    return isAuthRoute || isSplash || location == '/session'
        ? '/beranda'
        : null;
  }

  if (value is AuthUnauthenticated) {
    return isAuthRoute ? null : '/login';
  }

  return isAuthRoute ? null : '/splash';
}
