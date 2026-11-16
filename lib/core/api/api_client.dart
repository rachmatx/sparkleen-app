import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiResponse {
  const ApiResponse({this.data, this.meta = const {}});

  final Object? data;
  final Map<String, dynamic> meta;

  Map<String, dynamic> get asMap {
    final value = data;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  List<dynamic> get asList {
    final value = data;
    if (value is List) return value;
    return const [];
  }
}

class ApiClient {
  ApiClient({required this.tokenStorage, Dio? dio, String? baseUrl})
    : _dio = dio ?? Dio() {
    _origin = baseUrl ?? ApiConfig.apiBase;
    tokenStorage.requestOrigin = _origin;
    _dio.options
      ..baseUrl = _origin
      ..connectTimeout = const Duration(seconds: 15)
      ..sendTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 15)
      ..responseType = ResponseType.json
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final allowedWhenLocked = options.path.startsWith('/auth/');
          if (tokenStorage.requestOrigin != _origin ||
              (tokenStorage.sessionLocked && !allowedWhenLocked)) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: const ApiException(
                  code: 'SESSION_LOCKED',
                  message: 'Buka sesi terlebih dahulu.',
                ),
              ),
            );
            return;
          }
          final token = await tokenStorage.read();
          if (tokenStorage.requestOrigin != _origin) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: const ApiException(
                  code: 'SERVER_CHANGED',
                  message: 'Server berubah. Coba lagi.',
                ),
              ),
            );
            return;
          }
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthEndpoint = error.requestOptions.path.startsWith('/auth/');
          if (error.response?.statusCode == 401 &&
              !isAuthEndpoint &&
              tokenStorage.requestOrigin == _origin) {
            final currentToken = await tokenStorage.read();
            final sentAuthorization =
                error.requestOptions.headers['Authorization'];
            // A late 401 from account A must not log account B out.
            if (currentToken != null &&
                sentAuthorization == 'Bearer $currentToken') {
              await onUnauthorized?.call();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  late final String _origin;
  final TokenStorage tokenStorage;

  /// Di-set oleh controller auth agar 401 dari endpoint terproteksi
  /// menghapus sesi tanpa membuat ketergantungan melingkar.
  Future<void> Function()? onUnauthorized;

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _execute(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<ApiResponse> post(String path, {Object? body}) {
    return _execute(() => _dio.post<dynamic>(path, data: body));
  }

  Future<ApiResponse> patch(String path, {Object? body}) {
    return _execute(() => _dio.patch<dynamic>(path, data: body));
  }

  Future<ApiResponse> delete(String path, {Object? body}) {
    return _execute(() => _dio.delete<dynamic>(path, data: body));
  }

  Future<ApiResponse> _execute(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      if (tokenStorage.requestOrigin != _origin) {
        throw const ApiException(
          code: 'SERVER_CHANGED',
          message: 'Server berubah. Muat ulang halaman.',
        );
      }
      return _wrap(response);
    } on DioException catch (error) {
      if (error.error is ApiException) throw error.error!;
      throw ApiException.fromDio(error);
    }
  }

  ApiResponse _wrap(Response<dynamic> response) {
    final body = response.data;
    if (body is Map) {
      final meta = body['meta'];
      return ApiResponse(
        data: body['data'],
        meta: meta is Map ? Map<String, dynamic>.from(meta) : const {},
      );
    }
    return ApiResponse(data: body);
  }
}
