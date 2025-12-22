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
  final int participantCount; // Legacy: maps to registration_count
  
  // NEW: Multiple participant counts for better tracking
  final int registrationCount;  // Đang đăng ký (chưa check-in)
  final int checkedInCount;     // Đã check-in (đang trong event)
  final int attendedCount;      // Đã hoàn thành tham dự
  final int totalParticipants;  // Tổng số người (trừ cancelled)
  final double averageRating;   // Điểm đánh giá trung bình
  final int ratingCount;        // Số lượng đánh giá
  
  // NEW: Saved events feature
  final bool isSaved;           // Người dùng đã lưu sự kiện này chưa
  final DateTime? savedAt;      // Thời điểm lưu
  
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
    
    // NEW: Multiple counts (with defaults for backward compatibility)
    this.registrationCount = 0,
    this.checkedInCount = 0,
    this.attendedCount = 0,
    this.totalParticipants = 0,
    this.averageRating = 0,
    this.ratingCount = 0,
    
    // NEW: Saved events (with defaults)
    this.isSaved = false,
    this.savedAt,
    
  this.status,
  this.riskLevel = '',
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  })  : date = date ?? DateTime.now(),
        startAt = startAt ?? date ?? DateTime.now();

  // ========== Helper Methods for Smart Display ==========
  
  /// Get active participants (registered + checked-in)
  int get activeParticipants => registrationCount + checkedInCount;
  
  /// Check if event is currently happening
  bool get isLive {
    final now = DateTime.now();
    final end = endAt;
    return now.isAfter(startAt) && (end == null || now.isBefore(end));
  }
  
  /// Check if event has ended
  bool get hasEnded {
    final now = DateTime.now();
    final end = endAt ?? startAt.add(const Duration(hours: 2)); // Default 2h duration
    return now.isAfter(end);
  }
  
  /// Get smart participant display text based on event status
  String get participantDisplayText {
    // No participants at all
    if (totalParticipants == 0) {
      return '0/$capacity';
    }
    
    // Event has ended - show attended count
    if (hasEnded && attendedCount > 0) {
      return '$attendedCount đã tham dự';
    }
    
    // Event is live and has checked-in people
    if (isLive && checkedInCount > 0) {
      if (registrationCount > 0) {
        return '$checkedInCount đã đến / $activeParticipants đã đăng ký';
      }
      return '$checkedInCount đã đến';
    }
    
    // Event hasn't started - show registrations
    if (registrationCount > 0) {
      return '$registrationCount/$capacity';
    }
    
    // Fallback to total participants
    return '$totalParticipants/$capacity';
  }
  
  /// Get short display (for cards)
  String get participantCountShort {
    if (totalParticipants == 0) return '0/$capacity';
    
    // Show most relevant count based on status
    if (hasEnded) {
      return '$attendedCount đã tham dự';
    } else if (isLive) {
      return '$checkedInCount/$totalParticipants';
    } else {
      return '$registrationCount/$capacity';
    }
  }
  
  /// Check if event is full (based on active participants)
  bool get isFull => activeParticipants >= capacity;
  
  /// Get availability text
  String get availabilityText {
    if (isFull) return 'Đã đầy';
    if (hasEnded) return 'Đã kết thúc';
    if (isLive) return 'Đang diễn ra';
    
    final remaining = capacity - activeParticipants;
    return 'Còn $remaining chỗ';
  }

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

    double parseDouble(dynamic raw) {
      if (raw == null) return 0;
      if (raw is double) return raw;
      if (raw is int) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 0;
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
      
      // Legacy field for backward compatibility
      participantCount: parseInt(json['registration_count']),
      
      // NEW: Multiple count fields (with fallbacks for old API)
      registrationCount: parseInt(json['registration_count']),
      checkedInCount: parseInt(json['checked_in_count']),
      attendedCount: parseInt(json['attended_count']),
      totalParticipants: parseInt(json['total_participants']),
      averageRating: parseDouble(json['average_rating']),
      ratingCount: parseInt(json['rating_count']),
      
      // NEW: Saved events feature
      isSaved: json['is_saved'] as bool? ?? false,
      savedAt: parseDate(json['saved_at']),
      
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
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'is_saved': isSaved,
      'saved_at': savedAt?.toIso8601String(),
      'status': status,
      'riskLevel': riskLevel,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

