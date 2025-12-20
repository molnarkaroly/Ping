import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ping/core/api/api_endpoints.dart';
import 'package:ping/core/api/auth_interceptor.dart';
import 'package:ping/features/auth/domain/auth_service.dart';

/// Provider for API client
final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiClient(authService);
});

/// Dio-based API client with JWT authentication
class ApiClient {
  late final Dio _dio;
  final AuthService _authService;

  ApiClient(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(AuthInterceptor(_authService, _dio));

    // Add logging in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('API: $obj'),
      ),
    );
  }

  Dio get dio => _dio;

  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// API Exception for handling errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';

  factory ApiException.fromDioError(DioException error) {
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Kapcsolódási időtúllépés';
        break;
      case DioExceptionType.connectionError:
        message = 'Nincs internetkapcsolat';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        if (statusCode == 401) {
          message = 'Lejárt munkamenet';
        } else if (statusCode == 403) {
          message = 'Hozzáférés megtagadva';
        } else if (statusCode == 404) {
          message = 'Nem található';
        } else if (statusCode == 500) {
          message = 'Szerverhiba';
        } else if (data is Map && data['detail'] != null) {
          message = data['detail'].toString();
        } else if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else {
          message = 'Hiba történt: $statusCode';
        }
        return ApiException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      default:
        message = 'Ismeretlen hiba történt';
    }
    return ApiException(message: message);
  }
}
