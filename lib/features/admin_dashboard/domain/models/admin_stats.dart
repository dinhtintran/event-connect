/// Admin Dashboard Statistics Model
class AdminStats {
  final AdminOverview overview;
  final EventsByStatus events;
  final RecentActivity recentActivity;
  final List<TopEvent> topEvents;
  final List<TopClub> topClubs;

  AdminStats({
    required this.overview,
    required this.events,
    required this.recentActivity,
    required this.topEvents,
    required this.topClubs,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      overview: AdminOverview.fromJson(json['overview'] ?? {}),
      events: EventsByStatus.fromJson(json['events'] ?? {}),
      recentActivity: RecentActivity.fromJson(json['recent_activity'] ?? {}),
      topEvents: (json['top_events'] as List<dynamic>?)
          ?.map((e) => TopEvent.fromJson(e))
          .toList() ?? [],
      topClubs: (json['top_clubs'] as List<dynamic>?)
          ?.map((e) => TopClub.fromJson(e))
          .toList() ?? [],
    );
  }
}

class AdminOverview {
  final int totalEvents;
  final int totalUsers;
  final int totalClubs;
  final int totalRegistrations;

  AdminOverview({
    required this.totalEvents,
    required this.totalUsers,
    required this.totalClubs,
    required this.totalRegistrations,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    return AdminOverview(
      totalEvents: json['total_events'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
      totalClubs: json['total_clubs'] ?? 0,
      totalRegistrations: json['total_registrations'] ?? 0,
    );
  }
}

class EventsByStatus {
  final int pending;
  final int approved;
  final int ongoing;
  final int completed;

  EventsByStatus({
    required this.pending,
    required this.approved,
    required this.ongoing,
    required this.completed,
  });

  factory EventsByStatus.fromJson(Map<String, dynamic> json) {
    return EventsByStatus(
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      ongoing: json['ongoing'] ?? 0,
      completed: json['completed'] ?? 0,
    );
  }
}

class RecentActivity {
  final int newEventsThisWeek;
  final int newUsersThisWeek;
  final int registrationsThisWeek;

  RecentActivity({
    required this.newEventsThisWeek,
    required this.newUsersThisWeek,
    required this.registrationsThisWeek,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      newEventsThisWeek: json['new_events_this_week'] ?? 0,
      newUsersThisWeek: json['new_users_this_week'] ?? 0,
      registrationsThisWeek: json['registrations_this_week'] ?? 0,
    );
  }
}

class TopEvent {
  final int id;
  final String title;
  final int registrationCount;
  final double averageRating;

  TopEvent({
    required this.id,
    required this.title,
    required this.registrationCount,
    required this.averageRating,
  });

  factory TopEvent.fromJson(Map<String, dynamic> json) {
    return TopEvent(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      registrationCount: json['registration_count'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
    );
  }
}

class TopClub {
  final int id;
  final String name;
  final int eventCount;
  final int memberCount;

  TopClub({
    required this.id,
    required this.name,
    required this.eventCount,
    required this.memberCount,
  });

  factory TopClub.fromJson(Map<String, dynamic> json) {
    return TopClub(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      eventCount: json['event_count'] ?? 0,
      memberCount: json['member_count'] ?? 0,
    );
  }
}

