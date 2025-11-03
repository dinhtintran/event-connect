class Club {
  final int id;
  final String name;
  final String description;
  final String faculty;
  final String contactEmail;
  final DateTime createdAt;
  final String createdBy;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.faculty,
    required this.contactEmail,
    required this.createdAt,
    required this.createdBy,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      faculty: json['faculty'],
      contactEmail: json['contact_email'],
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'faculty': faculty,
      'contact_email': contactEmail,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

