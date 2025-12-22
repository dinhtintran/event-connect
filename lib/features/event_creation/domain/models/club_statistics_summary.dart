class ClubFeedbackSummary {
  final String title;
  final double rating;
  final String comment;
  final String avatarUrl;

  const ClubFeedbackSummary({
    required this.title,
    required this.rating,
    required this.comment,
    this.avatarUrl = '',
  });

  factory ClubFeedbackSummary.fromJson(Map<String, dynamic> json) {
    return ClubFeedbackSummary(
      title: (json['title'] ?? '').toString(),
      rating: _toDouble(json['rating']),
      comment: (json['comment'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ?? '').toString(),
    );
  }
}

class ClubHighlightSummary {
  final String eventId;
  final String title;
  final String posterUrl;

  const ClubHighlightSummary({
    required this.eventId,
    required this.title,
    required this.posterUrl,
  });

  factory ClubHighlightSummary.fromJson(Map<String, dynamic> json) {
    return ClubHighlightSummary(
      eventId: (json['event_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      posterUrl: (json['poster_url'] ?? '').toString(),
    );
  }
}

class ClubStatisticsSummary {
  final String clubId;
  final DateTime? generatedAt;
  final bool isEmpty;
  final String? errorCode;
  final String? message;
  final int totalParticipants;
  final double attendanceRate;
  final int completedEvents;
  final double satisfactionLevel;
  final double participantsChange;
  final double attendanceChange;
  final int eventsChange;
  final double satisfactionChange;
  final List<int> monthlyAttendance;
  final Map<String, int> academicYearDistribution;
  final List<ClubFeedbackSummary> recentFeedbacks;
  final List<ClubHighlightSummary> eventHighlights;

  const ClubStatisticsSummary({
    this.clubId = '',
    this.generatedAt,
    this.isEmpty = true,
    this.errorCode,
    this.message,
    required this.totalParticipants,
    required this.attendanceRate,
    required this.completedEvents,
    required this.satisfactionLevel,
    required this.participantsChange,
    required this.attendanceChange,
    required this.eventsChange,
    required this.satisfactionChange,
    required this.monthlyAttendance,
    required this.academicYearDistribution,
    required this.recentFeedbacks,
    required this.eventHighlights,
  });

  factory ClubStatisticsSummary.empty() {
    return const ClubStatisticsSummary(
      isEmpty: true,
      totalParticipants: 0,
      attendanceRate: 0,
      completedEvents: 0,
      satisfactionLevel: 0,
      participantsChange: 0,
      attendanceChange: 0,
      eventsChange: 0,
      satisfactionChange: 0,
      monthlyAttendance: [0, 0, 0, 0, 0, 0],
      academicYearDistribution: {
        'Năm 1': 0,
        'Năm 2': 0,
        'Năm 3': 0,
        'Năm 4': 0,
      },
      recentFeedbacks: [],
      eventHighlights: [],
    );
  }

  factory ClubStatisticsSummary.fromJson(Map<String, dynamic> json) {
    final overview = _asMap(json['overview']);
    final changes = _asMap(json['changes']);
    final series = _asMap(json['series']);

    final monthlyAttendance = _ensureSixMonths(series['monthly_attendance']);
    final academicDistribution = _mapAcademicDistribution(series['academic_year_distribution']);
    final feedbacks = _parseFeedbacks(json['feedbacks']);
    final highlights = _parseHighlights(json['highlights']);

    final totalParticipants = _toInt(overview['total_participants']);
    final attendanceRate = _toDouble(overview['attendance_rate']);
    final completedEvents = _toInt(overview['completed_events']);
    final satisfactionLevel = _toDouble(overview['satisfaction_level']);

    final participantsChange = _toDouble(changes['participants_pct']);
    final attendanceChange = _toDouble(changes['attendance_pct']);
    final eventsChange = _toInt(changes['events_delta']);
    final satisfactionChange = _toDouble(changes['satisfaction_pct']);

    final bool explicitEmpty = json['is_empty'] == true;
    final bool derivedEmpty = totalParticipants == 0 &&
        completedEvents == 0 &&
        monthlyAttendance.every((value) => value == 0) &&
        highlights.isEmpty &&
        feedbacks.isEmpty;

    return ClubStatisticsSummary(
      clubId: (json['club_id'] ?? '').toString(),
      generatedAt: json['generated_at'] != null ? DateTime.tryParse(json['generated_at'].toString()) : null,
      isEmpty: explicitEmpty || derivedEmpty,
      errorCode: json['error_code']?.toString(),
      message: json['detail']?.toString() ?? json['message']?.toString(),
      totalParticipants: totalParticipants,
      attendanceRate: attendanceRate,
      completedEvents: completedEvents,
      satisfactionLevel: satisfactionLevel,
      participantsChange: participantsChange,
      attendanceChange: attendanceChange,
      eventsChange: eventsChange,
      satisfactionChange: satisfactionChange,
      monthlyAttendance: monthlyAttendance,
      academicYearDistribution: academicDistribution,
      recentFeedbacks: feedbacks,
      eventHighlights: highlights,
    );
  }

  bool get hasRealData {
    return !isEmpty &&
        (totalParticipants > 0 ||
            completedEvents > 0 ||
            monthlyAttendance.any((value) => value > 0) ||
            eventHighlights.isNotEmpty ||
            recentFeedbacks.isNotEmpty);
  }
}

List<ClubFeedbackSummary> _parseFeedbacks(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ClubFeedbackSummary.fromJson)
        .toList();
  }
  return const [];
}

List<ClubHighlightSummary> _parseHighlights(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ClubHighlightSummary.fromJson)
        .toList();
  }
  return const [];
}

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  return const {};
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

List<int> _ensureSixMonths(dynamic data) {
  if (data is List) {
    final parsed = data.map(_toInt).toList();
    if (parsed.length >= 6) {
      return parsed.sublist(parsed.length - 6);
    }
    return [...List<int>.filled(6 - parsed.length, 0), ...parsed];
  }
  return const [0, 0, 0, 0, 0, 0];
}

Map<String, int> _mapAcademicDistribution(dynamic data) {
  final defaultDistribution = {
    'Năm 1': 0,
    'Năm 2': 0,
    'Năm 3': 0,
    'Năm 4': 0,
  };

  if (data is Map) {
    final mapped = Map<String, int>.from(defaultDistribution);
    void assignIfPresent(String key, String label) {
      if (data[key] != null) {
        mapped[label] = _toInt(data[key]);
      }
    }

    assignIfPresent('freshman', 'Năm 1');
    assignIfPresent('sophomore', 'Năm 2');
    assignIfPresent('junior', 'Năm 3');
    assignIfPresent('senior', 'Năm 4');
    return mapped;
  }

  return defaultDistribution;
}
