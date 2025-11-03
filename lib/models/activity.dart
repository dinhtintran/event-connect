class Activity {
  final String id;
  final String icon;
  final String title;
  final String subtitle;
  final String timestamp;

  Activity({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      icon: json['icon'],
      title: json['title'],
      subtitle: json['subtitle'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'icon': icon,
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp,
    };
  }
}

