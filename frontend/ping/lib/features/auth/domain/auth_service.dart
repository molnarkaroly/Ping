import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ping/core/api/api_endpoints.dart';
import 'package:ping/features/auth/domain/user_model.dart';

// Keys for SharedPreferences
const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _userKey = 'auth_user';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});

/// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateStream;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.user);
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.isAuthenticated) ?? false;
});

/// Auth state class
class AuthState {
  final bool isAuthenticated;
  final User? user;
  final String? accessToken;
  final String? refreshToken;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  const AuthState.initial() : this();

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

/// Auth service for handling authentication with real API
class AuthService {
  final SharedPreferences _prefs;
  final _authStateController = StreamController<AuthState>.broadcast();
  late final Dio _dio;

  AuthService(this._prefs) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _loadSavedAuth();
  }

  Stream<AuthState> get authStateStream => _authStateController.stream;

  /// Load saved authentication from SharedPreferences
  Future<void> _loadSavedAuth() async {
    final accessToken = _prefs.getString(_accessTokenKey);
    final refreshToken = _prefs.getString(_refreshTokenKey);
    final userJson = _prefs.getString(_userKey);

    if (accessToken != null && userJson != null) {
      try {
        final user = User.fromJson(jsonDecode(userJson));
        _authStateController.add(
          AuthState(
            isAuthenticated: true,
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        );
      } catch (e) {
        await _clearStoredAuth();
        _authStateController.add(const AuthState.initial());
      }
    } else {
      _authStateController.add(const AuthState.initial());
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return AuthResult.failure('Kérlek töltsd ki az összes mezőt');
      }

      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final accessToken = data['access'] as String;
        final refreshToken = data['refresh'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);

        await _saveAuth(user, accessToken, refreshToken);

        _authStateController.add(
          AuthState(
            isAuthenticated: true,
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        );

        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Hibás email vagy jelszó');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return AuthResult.failure('Hibás email vagy jelszó');
      }
      final message =
          e.response?.data?['detail'] ?? 'Hiba történt a bejelentkezés során';
      return AuthResult.failure(message.toString());
    } catch (e) {
      return AuthResult.failure('Hiba történt a bejelentkezés során');
    }
  }

  /// Register new user
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        return AuthResult.failure('Kérlek töltsd ki az összes mezőt');
      }

      if (!email.contains('@')) {
        return AuthResult.failure('Érvénytelen email cím');
      }

      if (password.length < 6) {
        return AuthResult.failure(
          'A jelszónak legalább 6 karakter hosszúnak kell lennie',
        );
      }

      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final accessToken = data['access'] as String;
        final refreshToken = data['refresh'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);

        await _saveAuth(user, accessToken, refreshToken);

        _authStateController.add(
          AuthState(
            isAuthenticated: true,
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        );

        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Regisztráció sikertelen');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map) {
          if (data['email'] != null) {
            return AuthResult.failure('Ez az email cím már használatban van');
          }
          if (data['detail'] != null) {
            return AuthResult.failure(data['detail'].toString());
          }
        }
      }
      return AuthResult.failure('Hiba történt a regisztráció során');
    } catch (e) {
      return AuthResult.failure('Hiba történt a regisztráció során');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      final refreshToken = getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(
          ApiEndpoints.logout,
          data: {'refresh': refreshToken},
          options: Options(headers: {'Authorization': 'Bearer ${getToken()}'}),
        );
      }
    } catch (e) {
      // Ignore logout errors
    }
    await _clearStoredAuth();
    _authStateController.add(const AuthState.initial());
  }

  /// Update tokens (called by auth interceptor after refresh)
  Future<void> updateTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await _prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  /// Save auth data to SharedPreferences
  Future<void> _saveAuth(
    User user,
    String accessToken,
    String refreshToken,
  ) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Clear stored auth data
  Future<void> _clearStoredAuth() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userKey);
  }

  /// Get current stored access token
  String? getToken() => _prefs.getString(_accessTokenKey);

  /// Get current stored refresh token
  String? getRefreshToken() => _prefs.getString(_refreshTokenKey);

  /// Check if user is logged in (synchronous check)
  bool isLoggedIn() => _prefs.getString(_accessTokenKey) != null;

  void dispose() {
    _authStateController.close();
  }
}

/// Result of auth operations
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  const AuthResult._({required this.isSuccess, this.user, this.errorMessage});

  factory AuthResult.success(User user) =>
      AuthResult._(isSuccess: true, user: user);

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
