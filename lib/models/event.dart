class Event {
  // Core fields (always present)
  final String id;
  final String title;

  // "Dev" simplified fields (kept for backward compatibility)
  final String? imageUrl;
  final DateTime? date;
  final String location;
  final String? category;
  final bool isFeatured;

  // "Feature/approval" extended fields (nullable so both shapes work)
  final String? clubName;
  final String? clubId;
  final String? description;
  final String? locationDetail;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? posterUrl;
  final int? capacity;
  final int? participantCount;
  final String? status; // 'pending', 'approved', 'rejected'
  final String? riskLevel; // 'Thấp', 'Trung bình', 'Cao'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.title,
    // dev fields
    this.imageUrl,
    this.date,
    this.location = '',
    this.category,
    this.isFeatured = false,
    // extended fields
    this.clubName,
    this.clubId,
    this.description,
    this.locationDetail,
    this.startAt,
    this.endAt,
    this.posterUrl,
    this.capacity,
    this.participantCount,
    this.status,
    this.riskLevel,
    this.createdAt,
    this.updatedAt,
  });

  // Factory to support both legacy/simple and extended JSON shapes
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: (json['id'] ?? json['event_id']).toString(),
      title: json['title'] as String? ?? '',
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['poster_url']) as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      location: (json['location'] as String?) ?? '',
      category: json['category'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      clubName: json['clubName'] as String?,
      clubId: json['clubId']?.toString(),
      description: json['description'] as String?,
      locationDetail: json['locationDetail'] as String?,
      startAt: json['startAt'] != null ? DateTime.tryParse(json['startAt'].toString()) : null,
      endAt: json['endAt'] != null ? DateTime.tryParse(json['endAt'].toString()) : null,
      posterUrl: (json['poster_url'] ?? json['posterUrl']) as String?,
      capacity: json['capacity'] is int ? json['capacity'] as int : (json['capacity'] != null ? int.tryParse(json['capacity'].toString()) : null),
      participantCount: json['participantCount'] is int ? json['participantCount'] as int : (json['participantCount'] != null ? int.tryParse(json['participantCount'].toString()) : null),
      status: json['status'] as String?,
      riskLevel: json['riskLevel'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      'id': id,
      'title': title,
      'location': location,
      'isFeatured': isFeatured,
    };
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (date != null) map['date'] = date!.toIso8601String();
    if (category != null) map['category'] = category;
    if (clubName != null) map['clubName'] = clubName;
    if (clubId != null) map['clubId'] = clubId;
    if (description != null) map['description'] = description;
    if (locationDetail != null) map['locationDetail'] = locationDetail;
    if (startAt != null) map['startAt'] = startAt!.toIso8601String();
    if (endAt != null) map['endAt'] = endAt!.toIso8601String();
    if (posterUrl != null) map['poster_url'] = posterUrl;
    if (capacity != null) map['capacity'] = capacity;
    if (participantCount != null) map['participantCount'] = participantCount;
    if (status != null) map['status'] = status;
    if (riskLevel != null) map['riskLevel'] = riskLevel;
    if (createdAt != null) map['createdAt'] = createdAt!.toIso8601String();
    if (updatedAt != null) map['updatedAt'] = updatedAt!.toIso8601String();
    return map;
  }
}

