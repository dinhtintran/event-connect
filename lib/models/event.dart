class Event {
  final int id;
  final String title;
  final int clubId;
  final String description;
  final String location;
  final DateTime startAt;
  final DateTime endAt;
  final String posterUrl;
  final int capacity;
  final String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Event({
    required this.id,
    required this.title,
    required this.clubId,
    required this.description,
    required this.location,
    required this.startAt,
    required this.endAt,
    required this.posterUrl,
    required this.capacity,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      clubId: json['clubId'],
      description: json['description'],
      location: json['location'],
      startAt: DateTime.parse(json['startAt']),
      endAt: DateTime.parse(json['endAt']),
      posterUrl: json['poster_url'],
      capacity: json['capacity'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'clubId': clubId,
      'description': description,
      'location': location,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'poster_url': posterUrl,
      'capacity': capacity,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

