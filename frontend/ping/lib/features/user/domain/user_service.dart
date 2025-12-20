import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ping/core/api/api_client.dart';
import 'package:ping/core/api/api_endpoints.dart';
import 'package:ping/features/auth/domain/user_model.dart';

/// Provider for UserService
final userServiceProvider = Provider<UserService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserService(apiClient);
});

/// Provider for user profile
final userProfileProvider = FutureProvider<User>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.getProfile();
});

/// Provider for user limits
final userLimitsProvider = FutureProvider<UserLimits>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.getLimits();
});

/// User limits model
class UserLimits {
  final int emergencyLimitPerDay;
  final int emergencySentToday;
  final int remaining;

  const UserLimits({
    required this.emergencyLimitPerDay,
    required this.emergencySentToday,
    required this.remaining,
  });

  factory UserLimits.fromJson(Map<String, dynamic> json) {
    final limit = json['emergency_limit_per_day'] as int? ?? 3;
    final sent = json['emergency_sent_today'] as int? ?? 0;
    return UserLimits(
      emergencyLimitPerDay: limit,
      emergencySentToday: sent,
      remaining: json['remaining'] as int? ?? (limit - sent),
    );
  }
}

/// Check-in status model
class CheckInStatus {
  final bool isActive;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final Duration? timeRemaining;

  const CheckInStatus({
    this.isActive = false,
    this.startedAt,
    this.expiresAt,
    this.timeRemaining,
  });

  factory CheckInStatus.fromJson(Map<String, dynamic> json) {
    final expiresAt = json['expires_at'] != null
        ? DateTime.tryParse(json['expires_at'] as String)
        : null;
    return CheckInStatus(
      isActive: json['is_active'] as bool? ?? false,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      expiresAt: expiresAt,
      timeRemaining: expiresAt != null
          ? expiresAt.difference(DateTime.now())
          : null,
    );
  }
}

/// User search result model
class UserSearchResult {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? avatarUrl;
  final bool isFriend;
  final bool isPending;

  const UserSearchResult({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.isFriend = false,
    this.isPending = false,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'].toString(),
      name: json['nickname'] as String? ?? json['username'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isFriend: json['is_friend'] as bool? ?? false,
      isPending: json['has_pending_request'] as bool? ?? false,
    );
  }
}

/// Service for user operations
class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  /// Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userProfile);
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update user status
  Future<void> updateStatus(String status) async {
    try {
      await _apiClient.patch(ApiEndpoints.userStatus, data: {'status': status});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Register FCM token for push notifications
  Future<void> registerFcmToken(String token) async {
    try {
      await _apiClient.put(ApiEndpoints.fcmToken, data: {'fcm_token': token});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Search for users
  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.userSearch,
        queryParameters: {'q': query},
      );
      final data = response.data as List<dynamic>;
      return data
          .map(
            (json) => UserSearchResult.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get daily limits
  Future<UserLimits> getLimits() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userLimits);
      return UserLimits.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await _apiClient.delete(ApiEndpoints.deleteAccount);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Start check-in timer
  Future<CheckInStatus> startCheckIn({required Duration duration}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.checkinStart,
        data: {'duration_minutes': duration.inMinutes},
      );
      return CheckInStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Mark as safe (complete check-in)
  Future<void> markSafe() async {
    try {
      await _apiClient.post(ApiEndpoints.checkinSafe);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
