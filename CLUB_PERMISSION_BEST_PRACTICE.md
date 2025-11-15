# Best Practice: Club Permission System

## 📋 Overview

Hệ thống phân quyền cho Club Admin sử dụng **3 cơ chế song song**, nhưng có độ ưu tiên khác nhau.

## 🎯 4 Cấp độ Permission System

### 0. **User.role = 'system_admin'** (SUPER ADMIN) 🔥🔥🔥🔥
**Highest Authority** - Quản trị viên Hệ thống (Trường học)

- ✅ Có TẤT CẢ quyền hạn trong hệ thống
- ✅ Quản lý tất cả CLB và sự kiện
- ✅ Phê duyệt/từ chối sự kiện
- ✅ Xem thống kê toàn hệ thống
- ✅ KHÔNG cần ClubMembership

**Flutter Implementation:**
```dart
class User {
  bool get isSystemAdmin => role == 'system_admin';
  bool get canApproveEvents => isSystemAdmin;
  bool get canViewSystemStats => isSystemAdmin;
}
```

---

### 1. **ClubMembership.role** (CLUB LEVEL) ⭐️⭐️⭐️
**Source of Truth** - Nguồn chân lý chính cho quyền hạn TRONG CLB

```python
# Backend Model
class ClubMembership(models.Model):
    user = models.ForeignKey(User)
    club = models.ForeignKey(Club)
    role = models.CharField(choices=[
        ('member', 'Member'),      # Thành viên thường
        ('admin', 'Admin'),        # Quản trị viên/BCH
        ('president', 'President') # Chủ tịch CLB
    ])
```

**Flutter Model:**
```dart
class Profile {
  final String? clubRole; // 'president', 'admin', 'member'
  
  bool get isClubPresident => clubRole == 'president';
  bool get isClubLeader => clubRole == 'president' || clubRole == 'admin';
  bool get isClubMember => clubRole != null;
}
```

**Ưu điểm:**
- ✅ Phản ánh đúng cơ cấu tổ chức thực tế
- ✅ Linh hoạt, dễ mở rộng
- ✅ Một user có thể có vai trò khác nhau ở các CLB khác nhau
- ✅ Dễ truy vấn và filter

**Use cases:**
- Check permission để xem participants
- Check permission để edit event
- Hiển thị vai trò của user trong CLB

---

### 2. **User.role** (SYSTEM LEVEL) ⭐️⭐️
Role chung trong toàn hệ thống

```python
# Backend Model
class User(AbstractUser):
    role = models.CharField(choices=[
        ('student', 'Student'),           # Sinh viên
        ('club_admin', 'Club Admin'),     # Admin CLB
        ('system_admin', 'System Admin')  # Admin Hệ thống (Trường)
    ])
```

**Flutter Model:**
```dart
class User {
  final String role; // 'student', 'club_admin', 'system_admin'
  
  bool get hasClubAdminPermission {
    // Highest priority: System admin
    if (role == 'system_admin') return true;
    
    // Priority 1: Check ClubMembership
    if (profile.isClubLeader) return true;
    
    // Priority 2: Check User role (fallback)
    if (role == 'club_admin') return true;
    
    return false;
  }
  
  bool get isSystemAdmin => role == 'system_admin';
}
```

**Ưu điểm:**
- ✅ Phân quyền cấp hệ thống
- ✅ Dễ check nhanh
- ✅ Backward compatibility

**Nhược điểm:**
- ❌ Không phân biệt vai trò cụ thể trong từng CLB
- ❌ Ít linh hoạt

**Use cases:**
- Routing/Navigation logic
- Hiển thị menu khác nhau cho các role
- Fallback khi không có ClubMembership data

---

### 3. **Club ForeignKey/ManyToMany** (LOW PRIORITY) ⭐️
Quan hệ trực tiếp giữa Club và User

```python
# Backend Model
class Club(models.Model):
    president = models.ForeignKey(User)  # Chủ tịch chính thức (1-1)
    admins = models.ManyToManyField(User) # Danh sách admin
```

**Ưu điểm:**
- ✅ Dễ query: `club.president.name`
- ✅ Đại diện chính thức

**Nhược điểm:**
- ❌ Không linh hoạt
- ❌ `president` chỉ lưu được 1 user
- ❌ `admins` M2M không có thêm metadata (như ngày bổ nhiệm, trạng thái, etc.)

**Use cases:**
- Hiển thị "Chủ tịch CLB" trên UI
- Query nhanh thông tin leader

---

## 🔐 Permission Check Flow (Best Practice)

### Backend Permission Class

```python
class IsClubLeader(permissions.BasePermission):
    """
    Permission for club-level actions (edit event, view participants, etc.)
    Priority: system_admin > ClubMembership.role > Club.president > Club.admins
    """
    def has_object_permission(self, request, view, obj):
        user = request.user
        club = obj.club if hasattr(obj, 'club') else obj
        
        # Priority 0: System admin has ALL permissions 🔥
        if user.role == 'system_admin':
            return True
        
        # Priority 1: Check ClubMembership.role ⭐️⭐️⭐️
        membership = ClubMembership.objects.filter(
            user=user,
            club=club,
            role__in=['president', 'admin']
        ).exists()
        
        if membership:
            return True
        
        # Priority 2: Check Club.president (ForeignKey)
        if club.president == user:
            return True
        
        # Priority 3: Check Club.admins (ManyToMany)
        if user in club.admins.all():
            return True
        
        return False


class IsSystemAdmin(permissions.BasePermission):
    """
    Permission for system-level actions (approve events, view all stats, etc.)
    Only system_admin role
    """
    def has_permission(self, request, view):
        return request.user.role == 'system_admin'
```

### Flutter Permission Check

```dart
// Best Practice: Use helper methods
if (user.canViewParticipants) {
  // Load participants
}

if (user.canApproveEvents) {
  // Show approve button (system admin only)
}

// Implementation in User model
bool get canViewParticipants {
  // Highest priority: System admin
  if (role == 'system_admin') return true;
  
  // Priority 1: ClubMembership.role
  if (profile.isClubLeader) return true;
  
  // Priority 2: User.role (fallback)
  if (role == 'club_admin') return true;
  
  return false;
}

bool get canApproveEvents => role == 'system_admin';
```

---

## 💾 Backend API Response

Backend nên trả về `club_role` trong profile:

```json
{
  "id": 1,
  "username": "tech_admin",
  "role": "club_admin",
  "profile": {
    "display_name": "Tech Admin",
    "club_name": "Tech Club",
    "club_role": "president",  // ← FROM ClubMembership.role
    "student_id": null,
    "bio": ""
  }
}
```

---

## 🎨 UI/UX Guidelines

### Show Role Badge
```dart
Widget _buildRoleBadge(User user) {
  final clubRole = user.profile.clubRole;
  
  if (clubRole == 'president') {
    return Chip(
      label: Text('Chủ tịch'),
      backgroundColor: Colors.amber,
    );
  } else if (clubRole == 'admin') {
    return Chip(
      label: Text('Quản trị viên'),
      backgroundColor: Colors.blue,
    );
  }
  
  return SizedBox.shrink();
}
```

### Conditional Feature Access
```dart
Widget _buildEventActions(User user, Event event) {
  return Row(
    children: [
      // Everyone can view details
      ElevatedButton(
        onPressed: () => _viewEventDetail(event),
        child: Text('Chi tiết'),
      ),
      
      // Only club leaders can edit
      if (user.profile.isClubLeader)
        ElevatedButton(
          onPressed: () => _editEvent(event),
          child: Text('Chỉnh sửa'),
        ),
      
      // Only club leaders can view participants
      if (user.canViewParticipants)
        ElevatedButton(
          onPressed: () => _viewParticipants(event),
          child: Text('Người đăng ký'),
        ),
    ],
  );
}
```

---

## ⚠️ Common Mistakes

### ❌ BAD: Only check User.role
```dart
// DON'T DO THIS
if (user.role == 'club_admin') {
  // Show club admin features
}
```

**Problem**: Không phân biệt vai trò cụ thể trong CLB

### ✅ GOOD: Check ClubMembership.role first
```dart
// DO THIS
if (user.profile.isClubLeader) {
  // Show club leader features
} else if (user.role == 'club_admin') {
  // Fallback for users without ClubMembership data
}
```

---

### ❌ BAD: Hard-code permission check
```dart
// DON'T DO THIS
final canEdit = user.role == 'club_admin' || 
                user.role == 'system_admin';
```

**Problem**: Duplicate logic, khó maintain

### ✅ GOOD: Use helper methods
```dart
// DO THIS
final canEdit = user.canManageEvents;
```

---

## 🧪 Testing Scenarios

### Scenario 1: User with ClubMembership
```
User: tech_admin
  - User.role: 'club_admin'
  - ClubMembership.role: 'president' (Tech Club)

Expected: ✅ Can view participants, edit events
Priority: ClubMembership.role takes precedence
```

### Scenario 2: User without ClubMembership
```
User: legacy_admin
  - User.role: 'club_admin'
  - ClubMembership: null

Expected: ✅ Can view participants, edit events (fallback to User.role)
Priority: User.role as fallback
```

### Scenario 3: Regular club member
```
User: student1
  - User.role: 'student'
  - ClubMembership.role: 'member' (Tech Club)

Expected: ❌ Cannot view participants, cannot edit events
Reason: Only 'president' and 'admin' have permissions
```

### Scenario 4: Student (not club member)
```
User: student2
  - User.role: 'student'
  - ClubMembership: null

Expected: ❌ Cannot view participants, cannot edit events
Reason: No club affiliation
```

---

## 📝 Migration Guide

### For Backend Developers:

1. ✅ Ensure `/api/auth/me/` returns `club_role` in profile
2. ✅ Update permission classes to check ClubMembership first
3. ✅ Add ClubMembership data for all club admins

### For Frontend Developers:

1. ✅ Update User/Profile models to include `clubRole`
2. ✅ Add helper methods (`isClubLeader`, `canViewParticipants`)
3. ✅ Replace hard-coded permission checks with helper methods
4. ✅ Test with different user scenarios

---

## 🔗 Related Files

### Backend:
- `models.py` - User, Club, ClubMembership models
- `permissions.py` - IsClubLeader permission class
- `serializers.py` - UserSerializer with club_role

### Frontend:
- `lib/features/authentication/domain/models/user.dart` - User & Profile models
- `lib/features/event_creation/presentation/screens/event_participants_screen.dart`
- `lib/features/event_creation/presentation/screens/edit_event_screen.dart`

---

## ✨ Summary

**Best Practice Priority:**
1. 🥇 **ClubMembership.role** - Source of truth
2. 🥈 **User.role** - System-level fallback
3. 🥉 **Club.president/admins** - Display only

**Remember:**
- Always check `ClubMembership.role` first
- Use helper methods instead of hard-coded checks
- Backend must return `club_role` in API response

---

*Last updated: November 14, 2025*
