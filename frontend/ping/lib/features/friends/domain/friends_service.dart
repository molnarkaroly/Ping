import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ping/core/api/api_client.dart';
import 'package:ping/core/api/api_endpoints.dart';
import 'package:ping/features/friends/domain/friend_model.dart';

/// Provider for FriendsService
final friendsServiceProvider = Provider<FriendsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FriendsService(apiClient);
});

/// Provider for friends list
final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final service = ref.watch(friendsServiceProvider);
  return service.getFriends();
});

/// Provider for friend requests
final friendRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  final service = ref.watch(friendsServiceProvider);
  return service.getFriendRequests();
});

/// Service for managing friends
class FriendsService {
  final ApiClient _apiClient;

  FriendsService(this._apiClient);

  /// Get list of friends
  Future<List<Friend>> getFriends() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.friends);
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Friend.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    try {
      await _apiClient.delete(ApiEndpoints.friendById(friendId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Block a friend
  Future<void> blockFriend(String friendId) async {
    try {
      await _apiClient.post(ApiEndpoints.blockFriend(friendId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Set VIP status for a friend
  Future<void> setVipStatus(String friendId, bool isVip) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.vipFriend(friendId),
        data: {'is_vip': isVip},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Send friend request
  Future<void> sendFriendRequest(String userId) async {
    try {
      await _apiClient.post(
        ApiEndpoints.friendRequest,
        data: {'receiver_id': int.parse(userId)},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Respond to friend request (accept/reject)
  Future<void> respondToRequest(
    String requestId, {
    required bool accept,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.friendRequestById(requestId),
        data: {'status': accept ? 'accepted' : 'rejected'},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get pending friend requests
  Future<List<FriendRequest>> getFriendRequests() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.friendRequests);
      final data = response.data as List<dynamic>;
      return data
          .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
