import 'package:event_connect/features/event_management/domain/models/event.dart';

/// Model for Event Approval
/// Represents an approval request for an event
class EventApproval {
  final int id; // EventApproval ID (dùng để approve/reject)
  final Event event; // Event details
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerName;
  final String comment;

  EventApproval({
    required this.id,
    required this.event,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewerName,
    this.comment = '',
  });

  factory EventApproval.fromJson(Map<String, dynamic> json) {
    return EventApproval(
      id: json['id'] as int,
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      status: json['status'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewerName: json['reviewer'] as String?,
      comment: json['comment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': event.toJson(),
      'status': status,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewer': reviewerName,
      'comment': comment,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
