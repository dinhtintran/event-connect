class User {
  final int id;
  final String username;
  final String? email;
  final Profile profile;

  User({required this.id, required this.username, this.email, required this.profile});

  factory User.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>? ?? {};
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      username: json['username'] ?? '',
      email: json['email'],
      profile: Profile.fromJson(profileJson),
    );
  }
}

class Profile {
  final String role;
  final String displayName;
  final String bio;
  final String? studentId;
  final String? clubName;
  final String? schoolCode;

  Profile({required this.role, required this.displayName, required this.bio, this.studentId, this.clubName, this.schoolCode});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      role: json['role'] ?? 'student',
      displayName: json['display_name'] ?? '',
      bio: json['bio'] ?? '',
      studentId: json['student_id'] as String?,
      clubName: json['club_name'] as String?,
      schoolCode: json['school_code'] as String?,
    );
  }
}
