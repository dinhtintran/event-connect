/// Admin User Model - Represents system admin with highest privileges
class AdminUser {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role; // 'system_admin', 'club_admin', 'student'
  final String? studentId;
  final String? faculty;
  final String? phone;
  final String? avatar;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  
  // Permissions
  final AdminPermissions permissions;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.studentId,
    this.faculty,
    this.phone,
    this.avatar,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
    this.createdAt,
    this.lastLogin,
    required this.permissions,
  });

  bool get isSystemAdmin => role == 'system_admin' || isSuperuser;
  bool get isClubAdmin => role == 'club_admin';
  bool get isStudent => role == 'student';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      role: json['role'] ?? 'student',
      studentId: json['student_id'] ?? json['studentId'],
      faculty: json['faculty'],
      phone: json['phone'],
      avatar: json['avatar'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      isStaff: json['is_staff'] ?? json['isStaff'] ?? false,
      isSuperuser: json['is_superuser'] ?? json['isSuperuser'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'])
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null),
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'])
          : (json['lastLogin'] != null ? DateTime.tryParse(json['lastLogin']) : null),
      permissions: AdminPermissions.fromJson(json['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'student_id': studentId,
      'faculty': faculty,
      'phone': phone,
      'avatar': avatar,
      'is_active': isActive,
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'permissions': permissions.toJson(),
    };
  }
}

/// Admin Permissions - Define what admin can do
class AdminPermissions {
  final bool canManageUsers;
  final bool canManageEvents;
  final bool canManageClubs;
  final bool canViewReports;
  final bool canDeleteEvents;
  final bool canDeleteUsers;
  final bool canApproveEvents;
  final bool canRejectEvents;
  final bool canSendNotifications;

  AdminPermissions({
    this.canManageUsers = false,
    this.canManageEvents = false,
    this.canManageClubs = false,
    this.canViewReports = false,
    this.canDeleteEvents = false,
    this.canDeleteUsers = false,
    this.canApproveEvents = false,
    this.canRejectEvents = false,
    this.canSendNotifications = false,
  });

  // System admin has all permissions
  factory AdminPermissions.systemAdmin() {
    return AdminPermissions(
      canManageUsers: true,
      canManageEvents: true,
      canManageClubs: true,
      canViewReports: true,
      canDeleteEvents: true,
      canDeleteUsers: true,
      canApproveEvents: true,
      canRejectEvents: true,
      canSendNotifications: true,
    );
  }

  // Club admin has limited permissions
  factory AdminPermissions.clubAdmin() {
    return AdminPermissions(
      canManageUsers: false,
      canManageEvents: true, // Only their club's events
      canManageClubs: false,
      canViewReports: true,
      canDeleteEvents: false,
      canDeleteUsers: false,
      canApproveEvents: false,
      canRejectEvents: false,
      canSendNotifications: false,
    );
  }

  factory AdminPermissions.fromJson(Map<String, dynamic> json) {
    return AdminPermissions(
      canManageUsers: json['can_manage_users'] ?? false,
      canManageEvents: json['can_manage_events'] ?? false,
      canManageClubs: json['can_manage_clubs'] ?? false,
      canViewReports: json['can_view_reports'] ?? false,
      canDeleteEvents: json['can_delete_events'] ?? false,
      canDeleteUsers: json['can_delete_users'] ?? false,
      canApproveEvents: json['can_approve_events'] ?? false,
      canRejectEvents: json['can_reject_events'] ?? false,
      canSendNotifications: json['can_send_notifications'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'can_manage_users': canManageUsers,
      'can_manage_events': canManageEvents,
      'can_manage_clubs': canManageClubs,
      'can_view_reports': canViewReports,
      'can_delete_events': canDeleteEvents,
      'can_delete_users': canDeleteUsers,
      'can_approve_events': canApproveEvents,
      'can_reject_events': canRejectEvents,
      'can_send_notifications': canSendNotifications,
    };
  }
}
