class Approval {
  final int id;
  final int eventId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? comment;
  final DateTime? decidedAt;
  final int approverId;

  Approval({
    required this.id,
    required this.eventId,
    required this.status,
    this.comment,
    this.decidedAt,
    required this.approverId,
  });

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      id: json['id'],
      eventId: json['eventId'],
      status: json['status'],
      comment: json['comment'],
      decidedAt: json['decidedAt'] != null 
          ? DateTime.parse(json['decidedAt']) 
          : null,
      approverId: json['approverId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'status': status,
      'comment': comment,
      'decidedAt': decidedAt?.toIso8601String(),
      'approverId': approverId,
    };
  }
}

