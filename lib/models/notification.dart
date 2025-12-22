class AppNotification {
  final String id; // Can be int or string
  final int userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;
  final int? eventId;
  final int? clubId;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.readAt,
    this.eventId,
    this.clubId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    String parseId(dynamic raw) {
      if (raw == null) return '';
      return raw is String ? raw : raw.toString();
    }

    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString());
    }

    return AppNotification(
      id: parseId(json['id']),
      userId: json['user'] is int 
          ? json['user'] as int 
          : (json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user']?.toString() ?? json['user_id']?.toString() ?? '0') ?? 0),
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] is bool ? json['is_read'] as bool : (json['isRead'] ?? false),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      readAt: parseDate(json['read_at'] ?? json['readAt']),
      eventId: json['event'] is int 
          ? json['event'] as int? 
          : (json['event_id'] is int ? json['event_id'] as int? : (json['event'] != null || json['event_id'] != null ? int.tryParse((json['event'] ?? json['event_id']).toString()) : null)),
      clubId: json['club'] is int 
          ? json['club'] as int? 
          : (json['club_id'] is int ? json['club_id'] as int? : (json['club'] != null || json['club_id'] != null ? int.tryParse((json['club'] ?? json['club_id']).toString()) : null)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'event_id': eventId,
      'club_id': clubId,
    };
  }
}

