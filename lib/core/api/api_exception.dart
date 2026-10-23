import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fields = const {},
  });

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, List<String>> fields;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetworkError => code == 'NETWORK_ERROR';

  String? fieldError(String field) {
    final messages = fields[field];
    if (messages == null || messages.isEmpty) return null;
    return messages.first;
  }

  int? get retryAfterSeconds => int.tryParse(fieldError('retry_after') ?? '');

  static const _fallbackMessage = 'Terjadi kesalahan. Silakan coba lagi.';

  factory ApiException.fromResponse(Response<dynamic> response) {
    final statusCode = response.statusCode;
    var code = 'HTTP_${statusCode ?? 0}';
    var message = _fallbackMessage;
    var fields = const <String, List<String>>{};

    final body = response.data;
    final error = body is Map ? body['error'] : null;
    if (error is Map) {
      if (error['code'] is String) code = error['code'] as String;
      if (error['message'] is String) message = error['message'] as String;
      fields = _parseFields(error['fields']);
    }

    return ApiException(
      code: code,
      message: message,
      statusCode: statusCode,
      fields: fields,
    );
  }

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const ApiException(
          code: 'NETWORK_ERROR',
          message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null) return ApiException.fromResponse(response);
        return const ApiException(
          code: 'NETWORK_ERROR',
          message: 'Server tidak merespons dengan benar.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          code: 'REQUEST_CANCELLED',
          message: 'Permintaan dibatalkan.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          code: 'BAD_CERTIFICATE',
          message: 'Sertifikat server tidak valid.',
        );
      case DioExceptionType.unknown:
        return const ApiException(
          code: 'NETWORK_ERROR',
          message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
    }
  }

  static Map<String, List<String>> _parseFields(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): switch (entry.value) {
          List<dynamic> values => values.map((value) => value.toString()).toList(),
          null => const <String>[],
          final value => [value.toString()],
        },
    };
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
