import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sparkleen_mobile/core/platform/app_orientation.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/core/widgets/app_shell.dart';

class _Tab extends StatefulWidget {
  const _Tab(this.label);
  final String label;
  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  int count = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      children: [
        Text(widget.label),
        TextButton(
          onPressed: () => setState(() => count++),
          child: Text('Count $count'),
        ),
        for (var i = 0; i < 30; i++)
          SizedBox(height: 50, child: Text('Item $i')),
      ],
    ),
  );
}

void main() {
  testWidgets(
    'startup requests only portrait-up and native activity locks portrait',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await lockAppOrientation();
      final orientation = calls.singleWhere(
        (call) => call.method == 'SystemChrome.setPreferredOrientations',
      );
      expect(orientation.arguments, ['DeviceOrientation.portraitUp']);
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains('android:screenOrientation="portrait"'));
      expect(
        manifest,
        contains(
          'android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY',
        ),
      );
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'tap, navbar slide and page swipe preserve root tabs / text $scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, shell) =>
                  AppShell(navigationShell: shell),
              branches: [
                for (final (path, label) in [
                  ('/home', 'Home content'),
                  ('/orders', 'Orders content'),
                  ('/profile', 'Profile content'),
                ])
                  StatefulShellBranch(
                    routes: [
                      GoRoute(path: path, builder: (_, _) => _Tab(label)),
                    ],
                  ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: buildAppTheme(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final nav = find.byKey(const ValueKey('tab-slide-bar'));
        expect(tester.getSize(nav).height, greaterThanOrEqualTo(60));
        expect(tester.getSize(nav).width, greaterThan(280));
        await tester.tap(find.text('Count 0'));
        await tester.pump();
        expect(find.text('Count 1'), findsOneWidget);
        // A vertical scroll must keep the current tab.
        await tester.drag(find.byType(ListView).first, const Offset(0, -120));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/home');
        final origin = tester.getTopLeft(nav);
        final size = tester.getSize(nav);
        await tester.dragFrom(
          origin + Offset(20, size.height / 2),
          Offset(size.width - 40, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text('Profile content'), findsOneWidget);
        await tester.drag(
          find.byKey(const ValueKey('tab-swipe-area')),
          const Offset(180, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text('Orders content'), findsOneWidget);
        await tester.drag(
          find.byKey(const ValueKey('tab-swipe-area')),
          const Offset(180, 0),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/home');
        // Stateful shell retains the counter across both kinds of swipe.
        await tester.drag(find.byType(ListView).first, const Offset(0, 160));
        await tester.pumpAndSettle();
        expect(find.text('Count 1'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Pesanan'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Orders content'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
