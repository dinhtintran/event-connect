class Event {
  // Use string id to be compatible with both branches (int or string IDs)
  final String id;
  final String title;

  // optional/general fields
  final String imageUrl;
  final DateTime date;
  final String location;
  final String category;
  final bool isFeatured;

  // approval/admin-related
  final String clubName;
  final String? clubId;
  final String description;
  final String locationDetail;
  final DateTime startAt;
  final DateTime? endAt;
  final String posterUrl;
  final int capacity;
  final int participantCount;
  final String? status;
  final String riskLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Event({
    required this.id,
    required this.title,
    this.imageUrl = '',
    DateTime? date,
    this.location = '',
    this.category = '',
    this.isFeatured = false,
  this.clubName = '',
  this.clubId,
  this.description = '',
  this.locationDetail = '',
    DateTime? startAt,
    this.endAt,
    this.posterUrl = '',
    this.capacity = 0,
    this.participantCount = 0,
  this.status,
  this.riskLevel = '',
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  })  : date = date ?? DateTime.now(),
        startAt = startAt ?? date ?? DateTime.now();

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

    // Parse club data from nested object
    final clubData = json['club'];
    String clubName = '';
    String? clubId;

    if (clubData != null && clubData is Map) {
      clubName = clubData['name'] ?? '';
      clubId = parseId(clubData['id']);
    }

    return Event(
      id: parseId(json['id']),
      title: (json['title'] ?? '') as String,
      imageUrl: (json['poster'] ?? json['poster_url'] ?? json['image_url'] ?? '') as String,
      date: parseDate(json['start_at']) ?? DateTime.now(),
      location: (json['location'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      isFeatured: (json['is_featured'] is bool) ? json['is_featured'] as bool : false,
      clubName: clubName,
      clubId: clubId,
      description: json['description'] as String? ?? '',
      locationDetail: json['location_detail'] as String? ?? '',
      startAt: parseDate(json['start_at']) ?? DateTime.now(),
      endAt: parseDate(json['end_at']),
      posterUrl: (json['poster'] ?? json['poster_url'] ?? '') as String,
      capacity: parseInt(json['capacity']),
      participantCount: parseInt(json['registration_count']),
      status: json['status'] as String?,
      riskLevel: '', // Not in API response
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      createdBy: json['created_by'] != null ? parseId(json['created_by']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
  'date': date.toIso8601String(),
      'location': location,
      'category': category,
      'isFeatured': isFeatured,
      'clubName': clubName,
      'clubId': clubId,
      'description': description,
      'locationDetail': locationDetail,
  'startAt': startAt.toIso8601String(),
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

