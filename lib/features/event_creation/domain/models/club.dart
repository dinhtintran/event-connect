class Club {
  final String id; // Can be int or string from backend
  final String name;
  final String? description;
  final String? faculty;
  final String? contactEmail;
  final String? contactPhone;
  final String? logo;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? presidentId;
  final List<int>? adminIds;
  final List<dynamic>? upcomingEvents;

  Club({
    required this.id,
    required this.name,
    this.description,
    this.faculty,
    this.contactEmail,
    this.contactPhone,
    this.logo,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.presidentId,
    this.adminIds,
    this.upcomingEvents,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    String parseId(dynamic raw) {
      if (raw == null) return '';
      return raw is String ? raw : raw.toString();
    }

    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString());
    }

    return Club(
      id: parseId(json['id']),
      name: json['name'] ?? '',
      description: json['description'] as String?,
      faculty: json['faculty'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      logo: json['logo'] as String?,
      status: json['status'] as String?,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      presidentId: json['president_id'] is int 
          ? json['president_id'] as int 
          : (json['president_id'] != null ? int.tryParse(json['president_id'].toString()) : null),
      adminIds: json['admin_ids'] != null 
          ? (json['admin_ids'] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList()
          : null,
      upcomingEvents: json['upcoming_events'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'faculty': faculty,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'logo': logo,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'president_id': presidentId,
      'admin_ids': adminIds,
      'upcoming_events': upcomingEvents,
    };
  }
}

