import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/security/biometric_service.dart';
import 'package:sparkleen_mobile/core/security/session_boundary.dart';
import 'package:sparkleen_mobile/core/settings/server_settings.dart';
import 'package:sparkleen_mobile/core/settings/server_page.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/auth/data/pelanggan.dart';
import 'package:sparkleen_mobile/features/auth/presentation/session_page.dart';
import 'package:sparkleen_mobile/features/pembayaran/application/payment_controller.dart';
import 'package:sparkleen_mobile/features/profil/presentation/security_page.dart';

import '../support/auth_fakes.dart';
import 'payment_test.dart' show FakePayments;

class FakeBiometrics extends BiometricService {
  FakeBiometrics(super.storage);
  bool answer = true, supported = true;
  int prompts = 0;
  Completer<bool>? delayed;
  @override
  Future<bool> available() async => supported;
  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    if (!supported) {
      throw const ApiException(
        code: 'BIOMETRIC_UNAVAILABLE',
        message: 'Biometrik belum tersedia',
      );
    }
    return delayed?.future ?? answer;
  }
}

class SlowProfile extends FakeAuthRepository {
  Completer<Pelanggan>? response;
  @override
  Future<Pelanggan> me() async {
    meCalls++;
    return response?.future ?? pelanggan;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  ProviderContainer setup(
    FakeTokenStorage storage,
    FakeAuthRepository repository,
    FakeBiometrics biometrics,
  ) => ProviderContainer.test(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(repository),
      biometricServiceProvider.overrideWithValue(biometrics),
    ],
  );
  for (final code in ['NETWORK_ERROR', 'HTTP_503']) {
    test('$code at startup preserves the token and exposes recovery', () async {
      final storage = FakeTokenStorage('valid-session');
      final repo = FakeAuthRepository()
        ..meError = ApiException(code: code, message: 'Jaringan terputus');
      final c = setup(storage, repo, FakeBiometrics(storage));
      expect(
        await c.read(authControllerProvider.future),
        isA<AuthSessionUnavailable>(),
      );
      expect(storage.token, 'valid-session');
      repo.meError = null;
      await c.read(authControllerProvider.notifier).retrySession();
      expect(c.read(authControllerProvider).value, isA<AuthAuthenticated>());
    });
  }
  test('enrolled session locks before fetching customer data and cancellation stays locked', () async {
    final storage = FakeTokenStorage('session-a')
      ..biometricBinding = jsonEncode({'token': 'session-a', 'payments': true});
    final repo = FakeAuthRepository();
    final bio = FakeBiometrics(storage)..answer = false;
    final c = setup(storage, repo, bio);
    expect(await c.read(authControllerProvider.future), isA<AuthLocked>());
    expect(repo.meCalls, 0);
    expect(storage.sessionLocked, true);
    await c.read(authControllerProvider.notifier).retrySession();
    expect(repo.meCalls, 0);
    expect(c.read(authControllerProvider).value, isA<AuthLocked>());
    await c.read(authControllerProvider.notifier).unlock();
    expect(repo.meCalls, 0);
    expect(storage.sessionLocked, true);
    bio.answer = true;
    await c.read(authControllerProvider.notifier).unlock();
    expect(repo.meCalls, 1);
    expect(storage.sessionLocked, false);
    expect(c.read(authControllerProvider).value, isA<AuthAuthenticated>());
  });
  test('invalid binding fails closed even when retry is requested', () async {
    final storage = FakeTokenStorage('session-a')..biometricBinding = '{broken';
    final repo = FakeAuthRepository();
    final c = setup(storage, repo, FakeBiometrics(storage));
    expect(
      await c.read(authControllerProvider.future),
      isA<AuthSessionUnavailable>(),
    );
    await c.read(authControllerProvider.notifier).retrySession();
    expect(repo.meCalls, 0);
    expect(storage.token, 'session-a');
  });
  test(
    'a setting belonging to another token does not enroll a new session',
    () async {
      final storage = FakeTokenStorage('session-b')
        ..biometricBinding = jsonEncode({
          'token': 'session-a',
          'payments': true,
        });
      final c = setup(storage, FakeAuthRepository(), FakeBiometrics(storage));
      expect(
        await c.read(authControllerProvider.future),
        isA<AuthAuthenticated>(),
      );
    },
  );
  test(
    'late biometric approval after logout cannot restore the session',
    () async {
      final storage = FakeTokenStorage('session-a')
        ..biometricBinding = jsonEncode({
          'token': 'session-a',
          'payments': true,
        });
      final repo = FakeAuthRepository();
      final bio = FakeBiometrics(storage)..delayed = Completer();
      final c = setup(storage, repo, bio);
      await c.read(authControllerProvider.future);
      final pending = c.read(authControllerProvider.notifier).unlock();
      await Future<void>.delayed(Duration.zero);
      await c.read(authControllerProvider.notifier).logout();
      bio.delayed!.complete(true);
      await pending;
      expect(storage.token, isNull);
      expect(storage.biometricBinding, isNull);
      expect(repo.meCalls, 0);
      expect(c.read(authControllerProvider).value, isA<AuthUnauthenticated>());
    },
  );
  test(
    'profile refresh is silent and preserves data if the connection fails',
    () async {
      final storage = FakeTokenStorage('session-a');
      final repo = FakeAuthRepository();
      final c = setup(storage, repo, FakeBiometrics(storage));
      await c.read(authControllerProvider.future);
      repo.meError = const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Offline',
      );
      await expectLater(
        c.read(authControllerProvider.notifier).refreshMe(),
        throwsA(isA<ApiException>()),
      );
      expect(c.read(authControllerProvider).isLoading, false);
      expect(c.read(authControllerProvider).value, isA<AuthAuthenticated>());
      expect(storage.token, 'session-a');
    },
  );
  test('late profile refresh cannot expose data after logout', () async {
    final storage = FakeTokenStorage('session-a');
    final repo = SlowProfile();
    final c = setup(storage, repo, FakeBiometrics(storage));
    await c.read(authControllerProvider.future);
    repo.response = Completer();
    final pending = c.read(authControllerProvider.notifier).refreshMe();
    await c.read(authControllerProvider.notifier).logout();
    repo.response!.complete(testPelanggan);
    await pending;
    expect(c.read(authControllerProvider).value, isA<AuthUnauthenticated>());
  });
  test(
    '401 during recovery clears the expired token and biometric preference',
    () async {
      final storage = FakeTokenStorage('session-a');
      final repo = FakeAuthRepository()
        ..meError = const ApiException(
          code: 'NETWORK_ERROR',
          message: 'Offline',
        );
      final c = setup(storage, repo, FakeBiometrics(storage));
      await c.read(authControllerProvider.future);
      repo.meError = const ApiException(
        code: 'AUTH_INVALID_TOKEN',
        message: 'Expired',
        statusCode: 401,
      );
      await c.read(authControllerProvider.notifier).retrySession();
      expect(storage.token, isNull);
      expect(c.read(authControllerProvider).value, isA<AuthUnauthenticated>());
    },
  );
  test('payment cancellation at biometric prompt issues no invoice', () async {
    final storage = FakeTokenStorage('session-a')
      ..biometricBinding = jsonEncode({'token': 'session-a', 'payments': true});
    final bio = FakeBiometrics(storage)..answer = false;
    final repo = FakePayments();
    final c = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        biometricServiceProvider.overrideWithValue(bio),
        paymentRepositoryProvider.overrideWithValue(repo),
      ],
    );
    final sub = c.listen(paymentControllerProvider(1), (_, _) {});
    addTearDown(sub.close);
    await c.read(paymentControllerProvider(1).future);
    await c.read(paymentControllerProvider(1).notifier).start('QRIS');
    expect(repo.starts, 0);
    expect(c.read(paymentControllerProvider(1)).value!.busy, false);
    bio.answer = true;
    await c.read(paymentControllerProvider(1).notifier).start('QRIS');
    expect(repo.starts, 1);
    expect(bio.prompts, 2);
  });
  test(
    'account changes while a payment prompt is open prevent invoice creation',
    () async {
      final storage = FakeTokenStorage('session-a')
        ..biometricBinding = jsonEncode({
          'token': 'session-a',
          'payments': true,
        });
      final bio = FakeBiometrics(storage)..delayed = Completer();
      final repo = FakePayments();
      final c = ProviderContainer.test(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          biometricServiceProvider.overrideWithValue(bio),
          paymentRepositoryProvider.overrideWithValue(repo),
        ],
      );
      final sub = c.listen(paymentControllerProvider(1), (_, _) {});
      addTearDown(sub.close);
      await c.read(paymentControllerProvider(1).future);
      final pending = c
          .read(paymentControllerProvider(1).notifier)
          .start('QRIS');
      await Future<void>.delayed(Duration.zero);
      c.read(customerSessionRevisionProvider.notifier).advance();
      await c.read(paymentControllerProvider(1).future);
      bio.delayed!.complete(true);
      await pending;
      expect(repo.starts, 0);
    },
  );

  test(
    'late 401 from an earlier session retry cannot clear a new login',
    () async {
      final storage = FakeTokenStorage('session-a');
      final repo = SlowProfile();
      final c = setup(storage, repo, FakeBiometrics(storage));
      await c.read(authControllerProvider.future);
      repo.response = Completer();
      final old = c.read(authControllerProvider.notifier).retrySession();
      await c.read(authControllerProvider.notifier).logout();
      storage.token = 'session-b';
      await c
          .read(authControllerProvider.notifier)
          .login(noTelp: '081234567890', pin: '654321');
      repo.response!.completeError(
        const ApiException(
          code: 'AUTH_INVALID_TOKEN',
          message: 'Expired old session',
          statusCode: 401,
        ),
      );
      await old;
      expect(storage.token, 'session-b');
      expect(c.read(authControllerProvider).value, isA<AuthAuthenticated>());
    },
  );
  testWidgets('an enrolled session locks after a minute in background', (
    tester,
  ) async {
    final storage = FakeTokenStorage('session-a')
      ..biometricBinding = jsonEncode({'token': 'session-a', 'payments': true});
    final bio = FakeBiometrics(storage);
    var now = DateTime(2026, 11, 11, 12);
    final c = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        biometricServiceProvider.overrideWithValue(bio),
        sessionClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    await c.read(authControllerProvider.future);
    await c.read(authControllerProvider.notifier).unlock();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: SessionBoundary(child: Text('Private content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(c.read(authControllerProvider).value, isA<AuthLocked>());
    expect(storage.sessionLocked, true);
  });
  test(
    'server address rejects credentials, paths, and public cleartext hosts',
    () {
      for (final url in [
        'http://example.com',
        'https://u:p@example.com',
        'https://example.com/api/v1',
        'https://example.com?token=secret',
        'http://0.0.0.0:8080',
        'garbage',
      ]) {
        expect(
          () => validateServerAddress(url, preview: true),
          throwsFormatException,
        );
      }
      expect(
        validateServerAddress('http://192.168.1.10:8080/', preview: true),
        'http://192.168.1.10:8080',
      );
      expect(
        () => validateServerAddress('http://192.168.1.10:8080', preview: false),
        throwsFormatException,
      );
      expect(
        validateServerAddress('https://test.example'),
        'https://test.example',
      );
    },
  );
  testWidgets(
    'native bridge cancellation never returns a successful authorization',
    (tester) async {
      const channel = MethodChannel('sparkleen/security');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        return call.method == 'available';
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final storage = FakeTokenStorage('session')
        ..biometricBinding = jsonEncode({'token': 'session', 'payments': true});
      final service = BiometricService(storage, channel: channel);
      expect(await service.confirmPayment('Verifikasi tagihan'), false);
      expect(calls, ['available', 'authenticate']);
    },
  );
  for (final brightness in Brightness.values) {
    for (final page in [
      const SecurityPage(),
      const SessionPage(),
      const ServerPage(),
    ]) {
      testWidgets('${page.runtimeType} fits 320px / large text / $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final storage = FakeTokenStorage('session-a');
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: [
              tokenStorageProvider.overrideWithValue(storage),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository()
                  ..meError = const ApiException(
                    code: 'NETWORK_ERROR',
                    message: 'Offline',
                  ),
              ),
              biometricServiceProvider.overrideWithValue(
                FakeBiometrics(storage),
              ),
            ],
            child: MaterialApp(
              theme: buildAppTheme(brightness: brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.8)),
                child: child!,
              ),
              home: page,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
