class Event {
  final int id;
  final String title;
  final String clubName;
  final String clubId;
  final String description;
  final String location;
  final String locationDetail;
  final DateTime startAt;
  final DateTime endAt;
  final String posterUrl;
  final int capacity;
  final int participantCount;
  final String status; // 'pending', 'approved', 'rejected'
  final String riskLevel; // 'Thấp', 'Trung bình', 'Cao'
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.clubName,
    required this.clubId,
    required this.description,
    required this.location,
    required this.locationDetail,
    required this.startAt,
    required this.endAt,
    required this.posterUrl,
    required this.capacity,
    required this.participantCount,
    required this.status,
    required this.riskLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      clubName: json['clubName'],
      clubId: json['clubId'],
      description: json['description'],
      location: json['location'],
      locationDetail: json['locationDetail'],
      startAt: DateTime.parse(json['startAt']),
      endAt: DateTime.parse(json['endAt']),
      posterUrl: json['poster_url'],
      capacity: json['capacity'],
      participantCount: json['participantCount'],
      status: json['status'],
      riskLevel: json['riskLevel'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'clubName': clubName,
      'clubId': clubId,
      'description': description,
      'location': location,
      'locationDetail': locationDetail,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'poster_url': posterUrl,
      'capacity': capacity,
      'participantCount': participantCount,
      'status': status,
      'riskLevel': riskLevel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

