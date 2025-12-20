/// Friend model
class Friend {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? status;
  final bool isVip;
  final bool isBlocked;
  final DateTime? lastSeen;

  const Friend({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.status,
    this.isVip = false,
    this.isBlocked = false,
    this.lastSeen,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'].toString(),
      name: json['name'] as String? ?? json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String?,
      isVip: json['is_vip'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'avatar_url': avatarUrl,
    'status': status,
    'is_vip': isVip,
    'is_blocked': isBlocked,
    'last_seen': lastSeen?.toIso8601String(),
  };

  Friend copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? status,
    bool? isVip,
    bool? isBlocked,
    DateTime? lastSeen,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      isVip: isVip ?? this.isVip,
      isBlocked: isBlocked ?? this.isBlocked,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// Friend request model
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserAvatar;
  final String toUserId;
  final String toUserName;
  final String? toUserAvatar;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserAvatar,
    required this.toUserId,
    required this.toUserName,
    this.toUserAvatar,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    // Django API returns 'sender' and 'receiver' objects
    final sender = json['sender'] as Map<String, dynamic>?;
    final receiver = json['receiver'] as Map<String, dynamic>?;

    return FriendRequest(
      id: json['id'].toString(),
      fromUserId: sender?['id']?.toString() ?? '',
      fromUserName:
          sender?['nickname'] as String? ??
          sender?['username'] as String? ??
          '',
      fromUserAvatar: sender?['avatar_url'] as String?,
      toUserId: receiver?['id']?.toString() ?? '',
      toUserName:
          receiver?['nickname'] as String? ??
          receiver?['username'] as String? ??
          '',
      toUserAvatar: receiver?['avatar_url'] as String?,
      status: FriendRequestStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

enum FriendRequestStatus {
  pending,
  accepted,
  rejected;

  static FriendRequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'rejected':
        return FriendRequestStatus.rejected;
      default:
        return FriendRequestStatus.pending;
    }
  }

  String toValue() => name;
}
