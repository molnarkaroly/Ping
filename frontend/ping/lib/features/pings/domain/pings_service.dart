import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ping/core/api/api_client.dart';
import 'package:ping/core/api/api_endpoints.dart';
import 'package:ping/features/pings/domain/ping_model.dart';

/// Provider for PingsService
final pingsServiceProvider = Provider<PingsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PingsService(apiClient);
});

/// Provider for ping history
final pingHistoryProvider = FutureProvider<List<Ping>>((ref) async {
  final service = ref.watch(pingsServiceProvider);
  return service.getHistory();
});

/// Service for managing pings
class PingsService {
  final ApiClient _apiClient;

  PingsService(this._apiClient);

  /// Send a ping to a friend
  Future<Ping> sendPing({
    required String receiverId,
    required PingType type,
    String? message,
  }) async {
    try {
      final request = SendPingRequest(
        receiverId: receiverId,
        type: type,
        message: message,
      );

      final response = await _apiClient.post(
        ApiEndpoints.sendPing,
        data: request.toJson(),
      );

      return Ping.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Mark ping as delivered (called automatically when notification received)
  Future<void> markDelivered(String pingId) async {
    try {
      await _apiClient.post(ApiEndpoints.pingDelivered(pingId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Mark ping as handshaked (user acknowledged the ping)
  Future<void> markHandshake(String pingId) async {
    try {
      await _apiClient.post(ApiEndpoints.pingHandshake(pingId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get ping history
  Future<List<Ping>> getHistory() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.pingHistory);
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Ping.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
