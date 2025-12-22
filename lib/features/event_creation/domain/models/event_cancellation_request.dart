/// Model cho yêu cầu hủy sự kiện
class EventCancellationRequest {
  final int id;
  final EventBasicInfo event;
  final UserBasicInfo? requestedBy; // Optional for create response
  final String reason;
  final String? refundPolicy;
  final String? alternativeAction;
  final String status; // 'pending', 'approved', 'rejected'
  final UserBasicInfo? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminComment;
  final DateTime createdAt;
  final DateTime? updatedAt; // Optional for create response

  EventCancellationRequest({
    required this.id,
    required this.event,
    this.requestedBy,
    required this.reason,
    this.refundPolicy,
    this.alternativeAction,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.adminComment,
    required this.createdAt,
    this.updatedAt,
  });

  factory EventCancellationRequest.fromJson(Map<String, dynamic> json) {
    return EventCancellationRequest(
      id: json['id'] as int,
      event: EventBasicInfo.fromJson(json['event'] as Map<String, dynamic>),
      requestedBy: json['requested_by'] != null
          ? UserBasicInfo.fromJson(json['requested_by'] as Map<String, dynamic>)
          : null,
      reason: json['reason'] as String,
      refundPolicy: json['refund_policy'] as String?,
      alternativeAction: json['alternative_action'] as String?,
      status: json['status'] as String,
      reviewedBy: json['reviewed_by'] != null 
          ? UserBasicInfo.fromJson(json['reviewed_by'] as Map<String, dynamic>)
          : null,
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      adminComment: json['admin_comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': event.toJson(),
      if (requestedBy != null) 'requested_by': requestedBy!.toJson(),
      'reason': reason,
      if (refundPolicy != null) 'refund_policy': refundPolicy,
      if (alternativeAction != null) 'alternative_action': alternativeAction,
      'status': status,
      if (reviewedBy != null) 'reviewed_by': reviewedBy!.toJson(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (adminComment != null) 'admin_comment': adminComment,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Đang chờ xét duyệt';
      case 'approved':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return status;
    }
  }
}

/// Thông tin cơ bản của sự kiện
class EventBasicInfo {
  final int id;
  final String title;
  final ClubBasicInfo? club;
  final String? status;

  EventBasicInfo({
    required this.id,
    required this.title,
    this.club,
    this.status,
  });

  factory EventBasicInfo.fromJson(Map<String, dynamic> json) {
    return EventBasicInfo(
      id: json['id'] as int,
      title: json['title'] as String,
      club: json['club'] != null 
          ? ClubBasicInfo.fromJson(json['club'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (club != null) 'club': club!.toJson(),
      if (status != null) 'status': status,
    };
  }
}

/// Thông tin cơ bản của CLB
class ClubBasicInfo {
  final int id;
  final String name;

  ClubBasicInfo({
    required this.id,
    required this.name,
  });

  factory ClubBasicInfo.fromJson(Map<String, dynamic> json) {
    return ClubBasicInfo(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

/// Thông tin cơ bản của người dùng
class UserBasicInfo {
  final int id;
  final String username;
  final String email;
  final String? fullName;

  UserBasicInfo({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
  });

  factory UserBasicInfo.fromJson(Map<String, dynamic> json) {
    return UserBasicInfo(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      if (fullName != null) 'full_name': fullName,
    };
  }
}
