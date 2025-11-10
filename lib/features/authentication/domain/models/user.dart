class User {
  final int id;
  final String username;
  final String? email;
  final String role;
  final Profile profile;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    required this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Backend returns role at top level, not in profile
    final role = json['role'] ?? 'student';

    // Create a profile object for additional info
    final profileJson = json['profile'] as Map<String, dynamic>? ?? {};
    // Backend returns role at user level, not in profile
    // So we need to pass it to Profile.fromJson
    final roleFromUser = json['role'] as String?;
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      username: json['username'] ?? '',
      email: json['email'],
      profile: Profile.fromJson(profileJson, roleFromUser: roleFromUser),
    );
  }
}

class Profile {
  final String displayName;
  final String bio;
  final String? studentId;
  final String? clubName;
  final String? schoolCode;

  Profile({
    required this.displayName,
    required this.bio,
    this.studentId,
    this.clubName,
    this.schoolCode,
  });

  factory Profile.fromJson(Map<String, dynamic> json, {String? roleFromUser}) {
    // Priority: roleFromUser (from user level) > json['role'] (from profile) > default 'student'
    return Profile(
      role: roleFromUser ?? json['role'] ?? 'student',
      displayName: json['display_name'] ?? '',
      bio: json['bio'] ?? '',
      studentId: json['student_id'] as String?,
      clubName: json['club_name'] as String?,
      schoolCode: json['school_code'] as String?,
    );
  }
}

