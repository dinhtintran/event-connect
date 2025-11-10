class UserProfile {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool isActive;
  final String? firstName;
  final String? lastName;
  final String dateJoined;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    this.firstName,
    this.lastName,
    required this.dateJoined,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      dateJoined: json['date_joined'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'is_active': isActive,
      'first_name': firstName,
      'last_name': lastName,
      'date_joined': dateJoined,
    };
  }
}

