class EventRegistration {
  final int id;
  final String status;
  final DateTime registeredAt;
  final int eventId;
  final int userId;

  EventRegistration({
    required this.id,
    required this.status,
    required this.registeredAt,
    required this.eventId,
    required this.userId,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['id'],
      status: json['status'],
      registeredAt: DateTime.parse(json['registeredAt']),
      eventId: json['eventId'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'registeredAt': registeredAt.toIso8601String(),
      'eventId': eventId,
      'userId': userId,
    };
  }
}

