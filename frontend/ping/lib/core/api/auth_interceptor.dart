import 'package:dio/dio.dart';
import 'package:ping/core/api/api_endpoints.dart';
import 'package:ping/features/auth/domain/auth_service.dart';

/// Interceptor for adding JWT tokens and handling refresh
class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;
  bool _isRefreshing = false;

  AuthInterceptor(this._authService, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Skip auth header for login/register endpoints
    final isAuthEndpoint =
        options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh');

    if (!isAuthEndpoint) {
      final token = _authService.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If 401 error and not already refreshing, try to refresh token
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = _authService.getRefreshToken();
        if (refreshToken != null) {
          // Try to refresh the token
          final response = await _dio.post(
            ApiEndpoints.refresh,
            data: {'refresh': refreshToken},
            options: Options(headers: {'Content-Type': 'application/json'}),
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data['access'];
            final newRefreshToken = response.data['refresh'];

            // Save new tokens
            await _authService.updateTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            // Retry original request with new token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';

            _isRefreshing = false;

            final retryResponse = await _dio.fetch(opts);
            return handler.resolve(retryResponse);
          }
        }
      } catch (e) {
        // Refresh failed, logout user
        await _authService.logout();
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }
}
