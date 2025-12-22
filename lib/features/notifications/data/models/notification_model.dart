class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? eventId;
  final String? clubId;
  final Map<String, dynamic>? eventData;
  final Map<String, dynamic>? clubData;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.eventId,
    this.clubId,
    this.eventData,
    this.clubData,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      eventId: json['event']?.toString(),
      clubId: json['club']?.toString(),
      eventData: json['event'] is Map ? json['event'] : null,
      clubData: json['club'] is Map ? json['club'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'event': eventId,
      'club': clubId,
    };
  }

  String getTimeAgo() {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}

