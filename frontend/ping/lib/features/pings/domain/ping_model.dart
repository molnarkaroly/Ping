/// Ping type enum
enum PingType {
  nudge,
  emergency;

  static PingType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'emergency':
        return PingType.emergency;
      default:
        return PingType.nudge;
    }
  }

  String toValue() => name;
}

/// Ping model
class Ping {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String receiverId;
  final String receiverName;
  final PingType type;
  final String? message;
  final bool isDelivered;
  final bool isHandshaked;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? handshakedAt;

  const Ping({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.receiverId,
    required this.receiverName,
    required this.type,
    this.message,
    this.isDelivered = false,
    this.isHandshaked = false,
    required this.createdAt,
    this.deliveredAt,
    this.handshakedAt,
  });

  factory Ping.fromJson(Map<String, dynamic> json) {
    return Ping(
      id: json['id'].toString(),
      senderId:
          json['sender']?['id']?.toString() ??
          json['sender_id']?.toString() ??
          '',
      senderName:
          json['sender']?['name'] as String? ??
          json['sender_name'] as String? ??
          '',
      senderAvatarUrl: json['sender']?['avatar_url'] as String?,
      receiverId:
          json['receiver']?['id']?.toString() ??
          json['receiver_id']?.toString() ??
          '',
      receiverName:
          json['receiver']?['name'] as String? ??
          json['receiver_name'] as String? ??
          '',
      type: PingType.fromString(json['type'] as String? ?? 'nudge'),
      message: json['message'] as String?,
      isDelivered: json['is_delivered'] as bool? ?? false,
      isHandshaked: json['is_handshaked'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      handshakedAt: json['handshaked_at'] != null
          ? DateTime.tryParse(json['handshaked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'sender_name': senderName,
    'receiver_id': receiverId,
    'receiver_name': receiverName,
    'type': type.toValue(),
    'message': message,
    'is_delivered': isDelivered,
    'is_handshaked': isHandshaked,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Send ping request model
class SendPingRequest {
  final String receiverId;
  final PingType type;
  final String? message;

  const SendPingRequest({
    required this.receiverId,
    required this.type,
    this.message,
  });

  Map<String, dynamic> toJson() => {
    'receiver_id': receiverId,
    'type': type.toValue(),
    if (message != null && message!.isNotEmpty) 'message': message,
  };
}
