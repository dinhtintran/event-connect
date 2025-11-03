class User {
  final int id;
  final String fullName;
  final String email;
  final String password;
  final String role; // 'admin', 'user', 'club_admin'
  final int? clubId;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.clubId,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      password: json['password'],
      role: json['role'],
      clubId: json['clubId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role,
      'clubId': clubId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

