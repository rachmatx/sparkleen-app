import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_page.dart';
import 'placeholder_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Masuk', icon: Icons.login_rounded),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Daftar', icon: Icons.person_add_rounded),
    ),
    GoRoute(
      path: '/activate',
      builder: (context, state) => const PlaceholderPage(
        title: 'Aktivasi PIN',
        icon: Icons.pin_rounded,
      ),
    ),
    GoRoute(
      path: '/beranda',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Beranda', icon: Icons.home_rounded),
    ),
  ],
);
