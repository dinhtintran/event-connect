class Event {
  // Use string id to be compatible with both branches (int or string IDs)
  final String id;
  final String title;

  // optional/general fields
  final String imageUrl;
  final DateTime? date;
  final String location;
  final String category;
  final bool isFeatured;

  // approval/admin-related
  final String? clubName;
  final String? clubId;
  final String? description;
  final String? locationDetail;
  final DateTime? startAt;
  final DateTime? endAt;
  final String posterUrl;
  final int capacity;
  final int participantCount;
  final String? status;
  final String? riskLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Event({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.date,
    this.location = '',
    this.category = '',
    this.isFeatured = false,
    this.clubName,
    this.clubId,
    this.description,
    this.locationDetail,
    this.startAt,
    this.endAt,
    this.posterUrl = '',
    this.capacity = 0,
    this.participantCount = 0,
    this.status,
    this.riskLevel,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    String parseId(dynamic raw) {
      if (raw == null) return '';
      return raw is String ? raw : raw.toString();
    }

    int parseInt(dynamic raw) {
      if (raw == null) return 0;
      if (raw is int) return raw;
      return int.tryParse(raw.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString());
    }

    return Event(
      id: parseId(json['id'] ?? json['event_id']),
      title: (json['title'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['poster_url'] ?? '') as String,
      date: parseDate(json['date']),
      location: (json['location'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      isFeatured: (json['isFeatured'] is bool) ? json['isFeatured'] as bool : false,
      clubName: json['clubName'] as String?,
      clubId: json['clubId'] != null ? (json['clubId'] is String ? json['clubId'] as String : json['clubId'].toString()) : null,
      description: json['description'] as String?,
      locationDetail: json['locationDetail'] as String?,
      startAt: parseDate(json['startAt']),
      endAt: parseDate(json['endAt']),
      posterUrl: (json['poster_url'] ?? json['posterUrl'] ?? '') as String,
      capacity: parseInt(json['capacity']),
      participantCount: parseInt(json['participantCount']),
      status: json['status'] as String?,
      riskLevel: json['riskLevel'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'date': date?.toIso8601String(),
      'location': location,
      'category': category,
      'isFeatured': isFeatured,
      'clubName': clubName,
      'clubId': clubId,
      'description': description,
      'locationDetail': locationDetail,
      'startAt': startAt?.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'poster_url': posterUrl,
      'capacity': capacity,
      'participantCount': participantCount,
      'status': status,
      'riskLevel': riskLevel,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

