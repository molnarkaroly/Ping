/// API Endpoints
class ApiEndpoints {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Auth
  static const String login = '/auth/login/';
  static const String logout = '/auth/logout/';
  static const String refresh = '/auth/refresh/';
  static const String register = '/auth/register/';

  // Friends
  static const String friends = '/friends/';
  static String friendById(String id) => '/friends/$id/';
  static String blockFriend(String id) => '/friends/$id/block/';
  static String vipFriend(String id) => '/friends/$id/vip/';
  static const String friendRequest = '/friends/request/';
  static String friendRequestById(String id) => '/friends/request/$id/';
  static const String friendRequests = '/friends/requests/';

  // Pings
  static const String sendPing = '/pings/send/';
  static String pingDelivered(String id) => '/pings/$id/delivered/';
  static String pingHandshake(String id) => '/pings/$id/handshake/';
  static const String pingHistory = '/pings/history/';

  // User
  static const String userStatus = '/user/status/';
  static const String fcmToken = '/user/fcm-token/';
  static const String userProfile = '/user/profile/';
  static const String userSearch = '/user/search/';
  static const String userLimits = '/user/limits/';
  static const String deleteAccount = '/user/me/';
  static const String checkinStart = '/user/checkin/start/';
  static const String checkinSafe = '/user/checkin/safe/';
}
