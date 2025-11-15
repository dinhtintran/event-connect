# 🔍 Phân tích lỗi: Club không xem được danh sách người đăng ký

## ❌ Vấn đề xác định

**Triệu chứng:** Khi club admin nhấn vào "Xem số người đăng ký", màn hình hiển thị thông báo lỗi permission.

**Log từ Flutter App:**
```
[EventApi] GET /api/events/3/participants/
[EventApi] DioException: type=DioExceptionType.badResponse status=403
Error loading participants: Exception: You do not have permission to view participants.
```

**Kết luận:** 
- ✅ Frontend code ĐÚNG - API call được gửi thành công
- ✅ Event ID hợp lệ - event 3, 4 tồn tại
- ❌ **BACKEND trả về 403 Forbidden** - User không có quyền truy cập

---

## 🎯 Nguyên nhân chính

Backend đang check permission KHÔNG ĐÚNG theo 4-tier hierarchy mà chúng ta đã thiết kế.

### Backend hiện tại có thể đang check:
1. ❌ Chỉ check `User.role == 'system_admin'` → Club admin bị từ chối
2. ❌ Chỉ check `ClubMembership.role` → Nếu không có ClubMembership record thì bị từ chối
3. ❌ Check cứng `Club.president == user` → Chỉ president được xem, admin không được

### Backend NÊN check theo thứ tự:
```python
# Priority 0: System admin has all access
if user.role == 'system_admin':
    return True

# Priority 1: ClubMembership.role (president or admin)
membership = ClubMembership.objects.filter(
    user=user, 
    club=event.club, 
    role__in=['president', 'admin']
).exists()
if membership:
    return True

# Priority 2: User.role fallback
if user.role == 'club_admin':
    # Check if user belongs to this club
    if user.profile.clubName == event.club.name:
        return True

# Priority 3: Legacy FK/M2M
if event.club.president == user or user in event.club.admins.all():
    return True

return False
```

---

## 🔧 Giải pháp

### ✅ Solution 1: Tạo ClubMembership record (Nhanh nhất)

Nếu user `music_admin` chưa có ClubMembership record cho club "Tech Club":

```python
# Vào Django shell
python manage.py shell

from django.contrib.auth import get_user_model
from clubs.models import Club, ClubMembership
from django.utils import timezone

User = get_user_model()

# Get user và club
user = User.objects.get(username='music_admin')
club = Club.objects.get(name='Tech Club')  # hoặc id=1

# Tạo ClubMembership
ClubMembership.objects.get_or_create(
    user=user,
    club=club,
    defaults={
        'role': 'admin',  # hoặc 'president'
        'joined_date': timezone.now()
    }
)

print(f"✅ Created ClubMembership: {user.username} -> {club.name} (admin)")
```

### ✅ Solution 2: Update Backend Permission Class (Lâu dài)

Update file `permissions.py`:

```python
# permissions.py
from rest_framework import permissions
from clubs.models import ClubMembership

class CanViewParticipants(permissions.BasePermission):
    """
    Permission to view event participants.
    Priority: system_admin > ClubMembership.role > User.role > Club FK/M2M
    """
    
    def has_permission(self, request, view):
        """Check if user has permission to access participants endpoint"""
        # Everyone authenticated can try (will check object-level permission)
        return request.user.is_authenticated
    
    def has_object_permission(self, request, view, obj):
        """Check if user can view participants for specific event"""
        user = request.user
        
        # Get event (obj might be Event or EventParticipant)
        event = obj if hasattr(obj, 'club') else obj.event
        club = event.club
        
        # 🔥 Priority 0: System admin can view all
        if hasattr(user, 'role') and user.role == 'system_admin':
            return True
        
        # ⭐️⭐️⭐️ Priority 1: ClubMembership (SOURCE OF TRUTH)
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            if membership.role in ['president', 'admin']:
                return True
        except ClubMembership.DoesNotExist:
            pass
        
        # ⭐️⭐️ Priority 2: User.role fallback
        if hasattr(user, 'role') and user.role == 'club_admin':
            # Also check if user belongs to this club
            try:
                profile = user.profile
                if profile.clubName == club.name:
                    return True
            except Exception:
                pass
        
        # ⭐️ Priority 3: Legacy FK/M2M
        if club.president == user:
            return True
        if hasattr(club, 'admins') and user in club.admins.all():
            return True
        
        return False
```

Update ViewSet trong `views.py`:

```python
# views.py
from rest_framework import viewsets, permissions
from .permissions import CanViewParticipants

class EventParticipantViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for event participants (Club Admin only)"""
    serializer_class = EventParticipantSerializer
    permission_classes = [permissions.IsAuthenticated, CanViewParticipants]
    
    def get_queryset(self):
        """Filter participants by event_id and user permission"""
        user = self.request.user
        event_id = self.request.query_params.get('event_id') or \
                   self.kwargs.get('event_pk')  # If using nested routing
        
        if not event_id:
            return EventParticipant.objects.none()
        
        try:
            event = Event.objects.get(id=event_id)
        except Event.DoesNotExist:
            return EventParticipant.objects.none()
        
        # Use same permission logic as has_object_permission
        club = event.club
        has_permission = False
        
        # System admin
        if hasattr(user, 'role') and user.role == 'system_admin':
            has_permission = True
        
        # ClubMembership
        if not has_permission:
            try:
                membership = ClubMembership.objects.get(user=user, club=club)
                if membership.role in ['president', 'admin']:
                    has_permission = True
            except ClubMembership.DoesNotExist:
                pass
        
        # User.role fallback
        if not has_permission:
            if hasattr(user, 'role') and user.role == 'club_admin':
                try:
                    profile = user.profile
                    if profile.clubName == club.name:
                        has_permission = True
                except Exception:
                    pass
        
        # Legacy
        if not has_permission:
            if club.president == user or user in club.admins.all():
                has_permission = True
        
        if has_permission:
            return EventParticipant.objects.filter(event=event)
        
        return EventParticipant.objects.none()
```

### ✅ Solution 3: Tạo Migration để sync tất cả Club Admins

```python
# migrations/0XXX_sync_club_memberships.py
from django.db import migrations
from django.utils import timezone

def create_missing_memberships(apps, schema_editor):
    """
    For all users with role='club_admin', create ClubMembership if missing
    """
    User = apps.get_model('auth', 'User')
    Profile = apps.get_model('profiles', 'Profile')
    Club = apps.get_model('clubs', 'Club')
    ClubMembership = apps.get_model('clubs', 'ClubMembership')
    
    club_admins = User.objects.filter(role='club_admin')
    created_count = 0
    
    for user in club_admins:
        try:
            profile = Profile.objects.get(user=user)
            if not profile.clubName:
                print(f"⚠️ User {user.username} has no clubName in profile")
                continue
            
            try:
                club = Club.objects.get(name=profile.clubName)
            except Club.DoesNotExist:
                print(f"❌ Club '{profile.clubName}' not found for user {user.username}")
                continue
            
            membership, created = ClubMembership.objects.get_or_create(
                user=user,
                club=club,
                defaults={
                    'role': 'admin',
                    'joined_date': user.date_joined or timezone.now()
                }
            )
            
            if created:
                created_count += 1
                print(f"✅ Created: {user.username} -> {club.name} (admin)")
        
        except Profile.DoesNotExist:
            print(f"⚠️ User {user.username} has no profile")
            continue
    
    print(f"\n🎉 Created {created_count} ClubMembership records")

class Migration(migrations.Migration):
    dependencies = [
        ('clubs', '0XXX_previous_migration'),
    ]
    
    operations = [
        migrations.RunPython(create_missing_memberships),
    ]
```

---

## 📊 Testing Steps

### Step 1: Verify Current State

```bash
# Check user info
python manage.py shell
>>> from django.contrib.auth import get_user_model
>>> User = get_user_model()
>>> user = User.objects.get(username='music_admin')
>>> print(f"Role: {user.role}")
>>> print(f"Club: {user.profile.clubName}")
>>> print(f"Club role: {user.profile.club_role}")  # Có thể chưa có field này

# Check ClubMembership
>>> from clubs.models import ClubMembership
>>> memberships = ClubMembership.objects.filter(user=user)
>>> print(f"Memberships: {memberships.count()}")
>>> for m in memberships:
...     print(f"  - {m.club.name}: {m.role}")
```

**Nếu memberships.count() == 0** → Không có ClubMembership → Dùng Solution 1

### Step 2: Apply Solution 1 (Quick Fix)

```python
# Trong Django shell
from django.contrib.auth import get_user_model
from clubs.models import Club, ClubMembership
from django.utils import timezone

User = get_user_model()
user = User.objects.get(username='music_admin')
club = Club.objects.get(id=1)  # hoặc name='Tech Club'

membership, created = ClubMembership.objects.get_or_create(
    user=user,
    club=club,
    defaults={'role': 'admin', 'joined_date': timezone.now()}
)

if created:
    print("✅ ClubMembership created!")
else:
    print(f"✅ ClubMembership exists: {membership.role}")
```

### Step 3: Test API Endpoint

```bash
# Get token
curl -X POST http://127.0.0.1:8000/api/accounts/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"music_admin","password":"music123"}'

# Copy access token từ response

# Test participants endpoint
curl -X GET http://127.0.0.1:8000/api/events/3/participants/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected:** Status 200 với list participants

### Step 4: Test trong Flutter App

1. Hot restart app: Nhấn `R` trong terminal
2. Login lại với `music_admin`
3. Navigate vào Club Home
4. Nhấn "Người ĐK" button
5. Check console logs:

```
👤 ========== USER PERMISSION DEBUG ==========
👤 Current user: music_admin
👤 User role: club_admin
👤 Club role: admin                    ← Nên thấy 'admin' hoặc 'president'
👤 Is club leader: true                ← Nên là true
👤 Can view participants: true
🔍 Loading participants for event: 3
[EventApi] GET /api/events/3/participants/
[EventApi] response 200                ← ✅ Success!
📡 getEventParticipants result: status=200
✅ Parsed 15 participants
```

---

## 📋 Checklist

### Backend Tasks:
- [ ] Check nếu ClubMembership table tồn tại
- [ ] Check nếu user `music_admin` có ClubMembership record
- [ ] Nếu không: Tạo ClubMembership record (Solution 1)
- [ ] Update permission class với 4-tier hierarchy (Solution 2)
- [ ] Update ViewSet permission_classes
- [ ] Tạo migration để sync tất cả club admins (Solution 3)
- [ ] Test API endpoint với Postman/curl
- [ ] Update `/api/accounts/me/` để trả về `club_role` field

### Frontend Tasks:
- [x] Added debug logging
- [x] Added user permission debug info
- [x] Updated error messages với chi tiết
- [ ] Test lại sau khi backend fix

---

## 🎯 TL;DR - Quick Fix

**Nhanh nhất:** Chạy command này trong Django shell:

```python
python manage.py shell

from django.contrib.auth import get_user_model
from clubs.models import Club, ClubMembership
from django.utils import timezone

User = get_user_model()

# Replace với username thực tế
user = User.objects.get(username='music_admin')
club = Club.objects.get(id=1)  # Tech Club

ClubMembership.objects.get_or_create(
    user=user,
    club=club,
    defaults={'role': 'admin', 'joined_date': timezone.now()}
)

print("✅ Done! Try accessing participants again in the app.")
```

Sau đó hot restart Flutter app (nhấn `R`) và test lại!

---

**Status:** 🔴 Backend permission issue - Cần tạo ClubMembership record hoặc update permission class  
**Priority:** 🔥 HIGH - Blocking club admin features
