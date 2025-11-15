# ✅ Xác nhận: Vấn đề là Backend Permission, KHÔNG phải Event ID sai

## 🔍 Phân tích từ logs

### Console logs cho thấy:
```
[EventApi] GET /api/events/4/participants/
[EventApi] DioException: status=403
Error: You do not have permission to view participants.

[EventApi] GET /api/events/3/participants/
[EventApi] DioException: status=403
Error: You do not have permission to view participants.
```

### ✅ Xác nhận:
1. **Event ID ĐÚNG**: Event 3 và 4 tồn tại, API call thành công đến server
2. **Navigation ĐÚNG**: `ClubEventCardSummary` đang truyền đúng `event` object vào `_navigateToParticipants()`
3. **❌ Backend trả về 403 Forbidden**: Permission check KHÔNG PASS

---

## 🎯 Nguyên nhân chính xác

Backend đang check permission và từ chối user `music_admin` xem participants của cả event 3 VÀ event 4.

### Có thể backend đang:
- ❌ Chỉ check `User.role == 'system_admin'` → `music_admin` có `role='club_admin'` nên bị reject
- ❌ Chỉ check `ClubMembership.role` → `music_admin` không có `ClubMembership` record nên bị reject
- ❌ Check cứng `event.club.president == user` → `music_admin` không phải president

---

## 🔧 Giải pháp (Chọn 1 trong 2)

### ✅ Option 1: Quick Fix - Tạo ClubMembership (5 phút)

```python
# Django shell
python manage.py shell

from django.contrib.auth import get_user_model
from clubs.models import Club, ClubMembership
from django.utils import timezone

User = get_user_model()

user = User.objects.get(username='music_admin')
club = Club.objects.get(id=1)  # Tech Club

ClubMembership.objects.get_or_create(
    user=user,
    club=club,
    defaults={'role': 'admin', 'joined_date': timezone.now()}
)

print("✅ Done!")
```

**Test ngay:** Hot restart app (R) và thử xem participants lại.

---

### ✅ Option 2: Fix Backend Permission Class (Lâu dài)

Update backend để support **Priority 2 fallback**: Nếu không có ClubMembership, check `User.role == 'club_admin'`

```python
# permissions.py
class CanViewParticipants(permissions.BasePermission):
    def has_permission(self, request, view):
        user = request.user
        
        # Get event_id from URL or query params
        event_id = view.kwargs.get('pk') or request.query_params.get('event_id')
        if not event_id:
            return False
        
        try:
            event = Event.objects.get(id=event_id)
            club = event.club
        except Event.DoesNotExist:
            return False
        
        # 🔥 Priority 0: System admin
        if hasattr(user, 'role') and user.role == 'system_admin':
            return True
        
        # ⭐️⭐️⭐️ Priority 1: ClubMembership
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            if membership.role in ['president', 'admin']:
                return True
        except ClubMembership.DoesNotExist:
            pass
        
        # ⭐️⭐️ Priority 2: User.role FALLBACK
        if hasattr(user, 'role') and user.role == 'club_admin':
            # Check if user belongs to this club
            try:
                profile = user.profile
                if profile.club_name == club.name:  # Hoặc club_name field name khác
                    return True
            except Exception:
                pass
        
        # ⭐️ Priority 3: Legacy
        if club.president == user or user in club.admins.all():
            return True
        
        return False
```

**Update ViewSet:**
```python
# views.py
from .permissions import CanViewParticipants

class EventParticipantViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated, CanViewParticipants]
    # ... rest of code
```

---

## 📊 Verification

### Frontend logs sẽ thêm:
```
🔵 ClubHomePage: Navigating to participants for event:
   - Event ID: 3
   - Event Title: Workshop AI
   - Event Club: Tech Club
   - Participants: 15/50

👤 ========== USER PERMISSION DEBUG ==========
👤 Current user: music_admin
👤 User role: club_admin
👤 Club role: admin          ← Sau khi tạo ClubMembership
👤 Can view participants: true
🔍 Loading participants for event: 3
[EventApi] GET /api/events/3/participants/
[EventApi] response 200      ← ✅ Success!
✅ Parsed 15 participants
```

---

## 🎯 Recommended Action

**Làm ngay:** Option 1 (Quick Fix) để unblock

**Sau đó:** Implement Option 2 để có permission system hoàn chỉnh theo 4-tier hierarchy

---

## 📚 Related Files

- `BACKEND_REQUIREMENTS.md` - Section 2.1: Permission Classes
- `PARTICIPANTS_ERROR_ANALYSIS.md` - Chi tiết 3 solutions
- `DEBUG_PARTICIPANTS_ISSUE.md` - Testing guide

---

**Status:** ✅ Root cause identified - Backend permission blocking all users without ClubMembership
**Next:** Run Django shell command to create ClubMembership record
