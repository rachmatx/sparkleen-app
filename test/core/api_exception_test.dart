import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';

Response<dynamic> _response(int statusCode, Object? data) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/me'),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  group('ApiException.fromResponse', () {
    test('membaca code, message, dan fields dari payload valid', () {
      final exception = ApiException.fromResponse(
        _response(422, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Data yang dikirim belum valid.',
            'fields': {
              'pin': ['PIN harus 6 digit angka.'],
              'no_telp': ['Nomor telepon wajib diisi.'],
            },
          },
        }),
      );

      expect(exception.code, 'VALIDATION_ERROR');
      expect(exception.message, 'Data yang dikirim belum valid.');
      expect(exception.statusCode, 422);
      expect(exception.fields['pin'], ['PIN harus 6 digit angka.']);
      expect(exception.fieldError('pin'), 'PIN harus 6 digit angka.');
      expect(exception.fieldError('nama'), isNull);
    });

    test('fallback saat payload bukan JSON kontrak', () {
      final exception = ApiException.fromResponse(
        _response(500, '<html>Internal Server Error</html>'),
      );

      expect(exception.code, 'HTTP_500');
      expect(exception.message, 'Terjadi kesalahan. Silakan coba lagi.');
      expect(exception.statusCode, 500);
      expect(exception.fields, isEmpty);
    });

    test('fallback saat error tidak punya fields', () {
      final exception = ApiException.fromResponse(
        _response(404, {
          'error': {'code': 'NOT_FOUND', 'message': 'Data tidak ditemukan.'},
        }),
      );

      expect(exception.code, 'NOT_FOUND');
      expect(exception.fields, isEmpty);
    });

    test('membaca retry_after pada error rate limit', () {
      final exception = ApiException.fromResponse(
        _response(429, {
          'error': {
            'code': 'AUTH_BLOCKED',
            'message': 'Terlalu banyak percobaan.',
            'fields': {
              'retry_after': ['60'],
            },
          },
        }),
      );

      expect(exception.retryAfterSeconds, 60);
    });
  });

  group('ApiException.fromDio', () {
    test('timeout dipetakan ke NETWORK_ERROR', () {
      final exception = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/me'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(exception.code, 'NETWORK_ERROR');
      expect(exception.isNetworkError, isTrue);
      expect(exception.statusCode, isNull);
    });

    test('badResponse memakai payload error dari server', () {
      final exception = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/me'),
          type: DioExceptionType.badResponse,
          response: _response(401, {
            'error': {
              'code': 'AUTH_INVALID_TOKEN',
              'message': 'Sesi Anda sudah berakhir.',
            },
          }),
        ),
      );

      expect(exception.code, 'AUTH_INVALID_TOKEN');
      expect(exception.statusCode, 401);
      expect(exception.isUnauthorized, isTrue);
    });
  });
}
