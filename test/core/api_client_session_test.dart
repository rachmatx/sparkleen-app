import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_client.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';

import '../support/auth_fakes.dart';

class _UnauthorizedAdapter implements HttpClientAdapter {
  _UnauthorizedAdapter(this.beforeResponse);
  final void Function() beforeResponse;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    beforeResponse();
    return ResponseBody.fromString(
      '{"error":{"code":"AUTH_INVALID_TOKEN","message":"Sesi berakhir."}}',
      401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a late unauthorized response cannot clear a newer session', () async {
    final storage = FakeTokenStorage('account-a');
    final dio = Dio()
      ..httpClientAdapter = _UnauthorizedAdapter(
        () => storage.token = 'account-b',
      );
    final client = ApiClient(tokenStorage: storage, dio: dio);
    var unauthorizedCalls = 0;
    client.onUnauthorized = () async {
      unauthorizedCalls++;
      await storage.clear();
    };
    await expectLater(client.get('/me'), throwsA(isA<ApiException>()));
    expect(unauthorizedCalls, 0);
    expect(storage.token, 'account-b');
  });

  test(
    'unauthorized response for the current session triggers session handling',
    () async {
      final storage = FakeTokenStorage('current-account');
      final dio = Dio()..httpClientAdapter = _UnauthorizedAdapter(() {});
      final client = ApiClient(tokenStorage: storage, dio: dio);
      var unauthorizedCalls = 0;
      client.onUnauthorized = () async {
        unauthorizedCalls++;
        await storage.clear();
      };
      await expectLater(client.get('/me'), throwsA(isA<ApiException>()));
      expect(unauthorizedCalls, 1);
      expect(storage.token, isNull);
    },
  );
  test(
    'an old server client cannot send a token after a server change',
    () async {
      final storage = FakeTokenStorage('new-server-token');
      var requests = 0;
      final dio = Dio()
        ..httpClientAdapter = _UnauthorizedAdapter(() => requests++);
      final old = ApiClient(
        tokenStorage: storage,
        dio: dio,
        baseUrl: 'https://old.example/api/v1',
      );
      ApiClient(tokenStorage: storage, baseUrl: 'https://new.example/api/v1');
      await expectLater(old.get('/me'), throwsA(isA<ApiException>()));
      expect(requests, 0);
      expect(storage.token, 'new-server-token');
    },
  );
  test('a locked session cannot send customer requests', () async {
    final storage = FakeTokenStorage('session')..sessionLocked = true;
    var requests = 0;
    final dio = Dio()
      ..httpClientAdapter = _UnauthorizedAdapter(() => requests++);
    final client = ApiClient(tokenStorage: storage, dio: dio);
    await expectLater(client.get('/me'), throwsA(isA<ApiException>()));
    expect(requests, 0);
    expect(storage.token, 'session');
  });
}
