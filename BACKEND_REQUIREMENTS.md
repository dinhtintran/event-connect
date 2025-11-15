# 🔧 Backend Requirements - Event Connect App

## 📋 Tổng quan
Document này liệt kê TẤT CẢ các thay đổi backend cần thực hiện để hỗ trợ permission system mới và các tính năng hiện tại của Flutter app.

**Priority**: 🔥 HIGH - App đang bị lỗi 401 permission do backend chưa implement đúng

---

## 🎯 1. API Response Changes (CRITICAL)

### 1.1. Thêm `club_role` vào `/api/auth/me/` response

**Current Response:**
```json
{
  "id": 1,
  "username": "user123",
  "email": "user@example.com",
  "role": "club_admin",
  "profile": {
    "displayName": "John Doe",
    "bio": "...",
    "studentId": "20210001",
    "clubName": "Tech Club",
    "schoolCode": "SCHOOL001"
    // ❌ THIẾU club_role
  }
}
```

**Required Response:**
```json
{
  "id": 1,
  "username": "user123",
  "email": "user@example.com",
  "role": "club_admin",
  "profile": {
    "displayName": "John Doe",
    "bio": "...",
    "studentId": "20210001",
    "clubName": "Tech Club",
    "schoolCode": "SCHOOL001",
    "clubRole": "president"  // ✅ THÊM FIELD NÀY
  }
}
```

**Implementation:**
```python
# serializers.py
class ProfileSerializer(serializers.ModelSerializer):
    clubRole = serializers.SerializerMethodField()
    
    class Meta:
        model = Profile
        fields = ['displayName', 'bio', 'studentId', 'clubName', 
                  'schoolCode', 'clubRole']
    
    def get_clubRole(self, obj):
        """
        Get user's role in their club from ClubMembership
        Returns: 'president', 'admin', 'member', or None
        """
        user = obj.user
        
        # Find user's club (assuming profile.clubName matches Club.name)
        if not obj.clubName:
            return None
        
        try:
            club = Club.objects.get(name=obj.clubName)
            membership = ClubMembership.objects.filter(
                user=user,
                club=club
            ).first()
            
            if membership:
                return membership.role  # 'president', 'admin', or 'member'
            
            return None
        except Club.DoesNotExist:
            return None
```

---

## 🔐 2. Permission System Updates (CRITICAL)

### 2.1. Update Permission Classes

Backend cần implement 4-tier permission hierarchy:

```
Priority 0: User.role = 'system_admin'     🔥 (Highest - bypass all checks)
Priority 1: ClubMembership.role            ⭐️⭐️⭐️ (Source of truth)
Priority 2: User.role = 'club_admin'       ⭐️⭐️ (Fallback)
Priority 3: Club ForeignKey/ManyToMany     ⭐️ (Legacy support)
```

**Updated Permission Class:**
```python
# permissions.py
from rest_framework import permissions

class IsClubLeader(permissions.BasePermission):
    """
    Permission for club-level actions (edit event, view participants, etc.)
    Checks: system_admin > ClubMembership.role > Club.president > Club.admins
    """
    
    def has_object_permission(self, request, view, obj):
        user = request.user
        
        # Get club from object
        club = obj.club if hasattr(obj, 'club') else obj
        
        # 🔥 Priority 0: System admin has ALL permissions
        if user.role == 'system_admin':
            return True
        
        # ⭐️⭐️⭐️ Priority 1: Check ClubMembership.role (SOURCE OF TRUTH)
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            if membership.role in ['president', 'admin']:
                return True
        except ClubMembership.DoesNotExist:
            pass
        
        # ⭐️⭐️ Priority 2: Check Club.president (ForeignKey fallback)
        if club.president == user:
            return True
        
        # ⭐️ Priority 3: Check Club.admins (ManyToMany fallback)
        if user in club.admins.all():
            return True
        
        return False


class IsSystemAdmin(permissions.BasePermission):
    """
    Permission for system-level actions (approve events, view stats, etc.)
    Only for User.role = 'system_admin'
    """
    
    def has_permission(self, request, view):
        return request.user.is_authenticated and \
               request.user.role == 'system_admin'


class CanViewParticipants(permissions.BasePermission):
    """
    Permission to view event participants
    Same logic as IsClubLeader
    """
    
    def has_object_permission(self, request, view, obj):
        user = request.user
        event = obj if hasattr(obj, 'club') else obj.event
        club = event.club
        
        # System admin can view all
        if user.role == 'system_admin':
            return True
        
        # Check ClubMembership
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            if membership.role in ['president', 'admin']:
                return True
        except ClubMembership.DoesNotExist:
            pass
        
        # Fallback checks
        if club.president == user or user in club.admins.all():
            return True
        
        return False
```

### 2.2. Update ViewSets

**Current (❌ Wrong):**
```python
class EventParticipantViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsClubAdmin]
    # ❌ IsClubAdmin chỉ check User.role
```

**Required (✅ Correct):**
```python
class EventParticipantViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, CanViewParticipants]
    # ✅ CanViewParticipants check theo priority hierarchy
    
    def get_queryset(self):
        user = self.request.user
        event_id = self.request.query_params.get('event_id')
        
        if not event_id:
            return EventParticipant.objects.none()
        
        try:
            event = Event.objects.get(id=event_id)
        except Event.DoesNotExist:
            return EventParticipant.objects.none()
        
        # Check permission using CanViewParticipants logic
        club = event.club
        
        # System admin sees all
        if user.role == 'system_admin':
            return EventParticipant.objects.filter(event=event)
        
        # Check ClubMembership
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            if membership.role in ['president', 'admin']:
                return EventParticipant.objects.filter(event=event)
        except ClubMembership.DoesNotExist:
            pass
        
        # Fallback checks
        if club.president == user or user in club.admins.all():
            return EventParticipant.objects.filter(event=event)
        
        # No permission
        return EventParticipant.objects.none()
```

---

## 🗄️ 3. Database & Model Updates

### 3.1. Ensure ClubMembership Records Exist

**Problem**: Nhiều user có `User.role = 'club_admin'` nhưng KHÔNG có ClubMembership record tương ứng.

**Solution**: Tạo migration để sync data

```python
# migrations/0XXX_sync_club_memberships.py
from django.db import migrations

def create_missing_memberships(apps, schema_editor):
    """
    For all users with role='club_admin' who have a clubName in profile,
    create ClubMembership record if not exists
    """
    User = apps.get_model('auth', 'User')
    Profile = apps.get_model('profiles', 'Profile')
    Club = apps.get_model('clubs', 'Club')
    ClubMembership = apps.get_model('clubs', 'ClubMembership')
    
    club_admins = User.objects.filter(role='club_admin')
    
    for user in club_admins:
        try:
            profile = Profile.objects.get(user=user)
            if not profile.clubName:
                continue
            
            # Find club
            try:
                club = Club.objects.get(name=profile.clubName)
            except Club.DoesNotExist:
                print(f"Club '{profile.clubName}' not found for user {user.username}")
                continue
            
            # Check if membership exists
            membership, created = ClubMembership.objects.get_or_create(
                user=user,
                club=club,
                defaults={
                    'role': 'admin',  # Default to 'admin' for club_admin users
                    'joined_date': user.date_joined
                }
            )
            
            if created:
                print(f"Created membership: {user.username} -> {club.name} (admin)")
        
        except Profile.DoesNotExist:
            continue

class Migration(migrations.Migration):
    dependencies = [
        ('clubs', '0XXX_previous_migration'),
    ]
    
    operations = [
        migrations.RunPython(create_missing_memberships),
    ]
```

### 3.2. Add Database Indexes (Performance)

```python
# models.py
class ClubMembership(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    joined_date = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        # ✅ Add composite index for faster lookups
        indexes = [
            models.Index(fields=['user', 'club']),
            models.Index(fields=['club', 'role']),
        ]
        unique_together = ['user', 'club']
```

---

## 📝 4. Error Response Format

### 4.1. Standardize Permission Denied Messages

**Current (❌ Bad):**
```json
{
  "detail": "You do not have permission to perform this action."
}
```

**Required (✅ Good):**
```json
{
  "detail": "You do not have permission to perform this action.",
  "code": "permission_denied",
  "required_role": "president or admin",
  "user_role": "member",
  "club_name": "Tech Club"
}
```

**Implementation:**
```python
# exceptions.py
from rest_framework.exceptions import PermissionDenied

class ClubPermissionDenied(PermissionDenied):
    def __init__(self, user, club, required_role="president or admin"):
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            user_role = membership.role
        except ClubMembership.DoesNotExist:
            user_role = "not a member"
        
        detail = {
            "detail": "You do not have permission to perform this action.",
            "code": "club_permission_denied",
            "required_role": required_role,
            "user_role": user_role,
            "club_name": club.name
        }
        super().__init__(detail)

# Usage in views
def has_object_permission(self, request, view, obj):
    # ... permission checks ...
    if not has_permission:
        raise ClubPermissionDenied(request.user, club)
```

---

## 🆕 5. New API Endpoints (Optional but Recommended)

### 5.1. Get User's Club Info
```python
# views.py
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_club_info(request):
    """
    Get current user's club membership info
    GET /api/users/me/club/
    """
    user = request.user
    
    try:
        profile = user.profile
        if not profile.clubName:
            return Response({
                "hasClub": False,
                "message": "User is not in any club"
            })
        
        club = Club.objects.get(name=profile.clubName)
        
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            return Response({
                "hasClub": True,
                "club": {
                    "id": club.id,
                    "name": club.name,
                    "description": club.description
                },
                "membership": {
                    "role": membership.role,
                    "joinedDate": membership.joined_date
                }
            })
        except ClubMembership.DoesNotExist:
            return Response({
                "hasClub": True,
                "club": {
                    "id": club.id,
                    "name": club.name
                },
                "membership": None,
                "warning": "ClubMembership record not found"
            })
    
    except (Profile.DoesNotExist, Club.DoesNotExist):
        return Response({
            "hasClub": False
        })
```

### 5.2. Check Permission API
```python
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_club_permission(request, club_id):
    """
    Check if user has admin permission in a club
    GET /api/clubs/{club_id}/check-permission/
    
    Returns:
    {
      "hasPermission": true/false,
      "role": "president"/"admin"/"member"/null,
      "reason": "system_admin" / "club_membership" / "fallback" / "none"
    }
    """
    user = request.user
    
    try:
        club = Club.objects.get(id=club_id)
    except Club.DoesNotExist:
        return Response({"error": "Club not found"}, status=404)
    
    # Check permission with reasons
    if user.role == 'system_admin':
        return Response({
            "hasPermission": True,
            "role": "system_admin",
            "reason": "system_admin"
        })
    
    try:
        membership = ClubMembership.objects.get(user=user, club=club)
        has_permission = membership.role in ['president', 'admin']
        return Response({
            "hasPermission": has_permission,
            "role": membership.role,
            "reason": "club_membership"
        })
    except ClubMembership.DoesNotExist:
        pass
    
    # Fallback checks
    if club.president == user or user in club.admins.all():
        return Response({
            "hasPermission": True,
            "role": "admin",
            "reason": "fallback"
        })
    
    return Response({
        "hasPermission": False,
        "role": None,
        "reason": "none"
    })
```

---

## ✅ 6. Testing Checklist

Backend team cần test các scenarios sau:

### 6.1. System Admin Tests
- [ ] System admin có thể view participants của BẤT KỲ event nào
- [ ] System admin có thể edit/delete BẤT KỲ event nào
- [ ] System admin có thể approve/reject events
- [ ] System admin có thể access admin dashboard
- [ ] System admin KHÔNG cần ClubMembership record

### 6.2. Club Admin Tests (với ClubMembership)
- [ ] User có ClubMembership.role = 'president' có thể view participants
- [ ] User có ClubMembership.role = 'admin' có thể edit events
- [ ] User có ClubMembership.role = 'member' KHÔNG thể view participants
- [ ] Club president có thể manage tất cả events của club mình

### 6.3. Fallback Tests
- [ ] User có `User.role = 'club_admin'` NHƯNG không có ClubMembership → vẫn có permission (fallback)
- [ ] User trong `Club.admins` ManyToMany → có permission
- [ ] User là `Club.president` ForeignKey → có permission

### 6.4. Permission Denied Tests
- [ ] Student user không thể access club admin features
- [ ] Club member không thể view participants
- [ ] Error response có đầy đủ thông tin (required_role, user_role, club_name)

### 6.5. API Response Tests
- [ ] `/api/auth/me/` trả về `profile.clubRole` đúng
- [ ] `clubRole` = 'president'/'admin'/'member' hoặc null
- [ ] `clubRole` match với ClubMembership.role trong database

---

## 🚀 7. Implementation Priority

### Phase 1: CRITICAL (Do ngay)
1. ✅ Update `/api/auth/me/` response - thêm `profile.clubRole`
2. ✅ Update permission classes với 4-tier hierarchy
3. ✅ Fix EventParticipantViewSet permission checks
4. ✅ Create migration để sync ClubMembership records

### Phase 2: Important (Trong tuần)
5. ✅ Improve error messages cho permission denied
6. ✅ Add database indexes cho performance
7. ✅ Test tất cả scenarios trong checklist

### Phase 3: Enhancement (Khi có thời gian)
8. ✅ Add `/api/users/me/club/` endpoint
9. ✅ Add `/api/clubs/{id}/check-permission/` endpoint
10. ✅ Add logging cho permission checks

---

## 📞 Contact & Support

Nếu có thắc mắc về implementation, liên hệ:
- Frontend Lead: [Tên người]
- Backend Lead: [Tên người]

Reference Documents:
- `CLUB_PERMISSION_BEST_PRACTICE.md` - Chi tiết về permission system
- Flutter code: `lib/features/authentication/domain/models/user.dart` - User model với permission helpers

---

**Last Updated**: November 14, 2025
**Status**: 🔴 Pending Backend Implementation
