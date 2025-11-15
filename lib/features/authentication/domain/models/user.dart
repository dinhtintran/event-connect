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
      role: role,
      profile: Profile.fromJson(profileJson, roleFromUser: roleFromUser),
    );
  }
  
  /// Best Practice: Check if user has club admin permissions
  /// Priority: system_admin > ClubMembership.role > User.role
  bool get hasClubAdminPermission {
    // Highest priority: System admin has all permissions
    if (role == 'system_admin') return true;
    
    // 1st priority: Check ClubMembership role (president or admin)
    if (profile.isClubLeader) return true;
    
    // 2nd priority: Check User role (fallback for backward compatibility)
    if (role == 'club_admin') return true;
    
    return false;
  }
  
  /// Check if user is system administrator (school admin)
  bool get isSystemAdmin => role == 'system_admin';
  
  /// Check if user can manage ANY club's events (system admin can manage all)
  bool get canManageEvents => hasClubAdminPermission;
  
  /// Check if user can view event participants
  bool get canViewParticipants => hasClubAdminPermission;
  
  /// Check if user can approve events (system admin only)
  bool get canApproveEvents => isSystemAdmin;
  
  /// Check if user can view system statistics (system admin only)
  bool get canViewSystemStats => isSystemAdmin;
}

class Profile {
  final String displayName;
  final String bio;
  final String? studentId;
  final String? clubName;
  final String? schoolCode;
  final String? clubRole; // Role in ClubMembership: 'president', 'admin', 'member'

  Profile({
    required this.displayName,
    required this.bio,
    this.studentId,
    this.clubName,
    this.schoolCode,
    this.clubRole,
  });

  factory Profile.fromJson(Map<String, dynamic> json, {String? roleFromUser}) {
    // Note: roleFromUser is accepted but not used since Profile doesn't store role
    // Role is stored at User level, not Profile level
    // clubRole comes from ClubMembership.role (if user is club member)
    return Profile(
      displayName: json['display_name'] ?? '',
      bio: json['bio'] ?? '',
      studentId: json['student_id'] as String?,
      clubName: json['club_name'] as String?,
      schoolCode: json['school_code'] as String?,
      clubRole: json['club_role'] as String?, // From ClubMembership.role
    );
  }
  
  /// Check if user is club president (best practice: check ClubMembership.role)
  bool get isClubPresident => clubRole == 'president';
  
  /// Check if user is club admin or president
  bool get isClubLeader => clubRole == 'president' || clubRole == 'admin';
  
  /// Check if user is club member (any role)
  bool get isClubMember => clubRole != null;
}

