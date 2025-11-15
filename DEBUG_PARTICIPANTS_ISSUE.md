# 🐛 Debug Guide: Club không xem được danh sách người đăng ký

## 🔍 Vấn đề
Club admin nhấn vào "Xem số người đăng ký" nhưng không hiển thị được danh sách.

## 📋 Các nguyên nhân có thể

### 1. ❌ Backend Permission Error (401/403)

**Triệu chứng:**
- Màn hình hiển thị: "Bạn không có quyền xem danh sách người tham gia"
- Console log: `❌ Error response: {"detail": "You do not have permission..."}` hoặc status 401/403

**Nguyên nhân:**
Backend đang check permission theo 1 trong các cách:
- ✅ Chỉ check `User.role == 'club_admin'` (nhưng user có thể là 'student')
- ✅ Chỉ check `ClubMembership.role` (nhưng ClubMembership record chưa được tạo)
- ✅ Check `Club.president` hoặc `Club.admins` (nhưng user chưa được add vào)

**Giải pháp:**
1. Check user hiện tại trong database:
```sql
SELECT u.id, u.username, u.role, p.clubName, p.clubRole 
FROM auth_user u 
LEFT JOIN profiles p ON u.id = p.user_id 
WHERE u.username = 'your_username';
```

2. Check ClubMembership record:
```sql
SELECT cm.id, cm.user_id, cm.club_id, cm.role, c.name as club_name
FROM club_memberships cm
JOIN clubs c ON cm.club_id = c.id
WHERE cm.user_id = YOUR_USER_ID;
```

3. Nếu **KHÔNG có ClubMembership record**:
   - Backend cần tạo migration để sync (xem `BACKEND_REQUIREMENTS.md` section 3.1)
   - Hoặc tạo manual:
   ```sql
   INSERT INTO club_memberships (user_id, club_id, role, joined_date)
   VALUES (YOUR_USER_ID, YOUR_CLUB_ID, 'admin', NOW());
   ```

4. Nếu **có ClubMembership nhưng vẫn lỗi**:
   - Backend permission class chưa implement đúng 4-tier hierarchy
   - Cần update permission class (xem `BACKEND_REQUIREMENTS.md` section 2.1)

---

### 2. ❌ Event ID không hợp lệ

**Triệu chứng:**
- Console log: `🔍 Loading participants for event: null` hoặc `undefined`
- Backend trả về 404 Not Found

**Nguyên nhân:**
Event object bị null hoặc ID không đúng format

**Giải pháp:**
Check navigation code trong `club_home_page.dart`:
```dart
// ✅ CORRECT
void _navigateToParticipants(Event event) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => EventParticipantsScreen(event: event),
    ),
  );
}

// ❌ WRONG
void _navigateToParticipants(Event event) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => EventParticipantsScreen(event: null), // Thiếu event
    ),
  );
}
```

---

### 3. ❌ Backend Endpoint không tồn tại

**Triệu chứng:**
- Console log: `[EventApi] DioException: type=response status=404`
- Backend log: `404 Not Found: /api/events/{id}/participants/`

**Nguyên nhân:**
Backend chưa implement endpoint này hoặc routing sai

**Giải pháp:**
1. Check backend urls.py:
```python
# events/urls.py
urlpatterns = [
    path('<int:pk>/participants/', views.EventParticipantListView.as_view(), name='event-participants'),
]
```

2. Check view exists:
```python
# events/views.py
class EventParticipantListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated, CanViewParticipants]
    
    def get_queryset(self):
        event_id = self.kwargs['pk']
        return EventParticipant.objects.filter(event_id=event_id)
```

---

### 4. ❌ DioProvider không gửi Authorization token

**Triệu chứng:**
- Console log: `❌ Error response: {"detail": "Authentication credentials were not provided"}`
- Status: 401 Unauthorized

**Nguyên nhân:**
Token không được attach vào request header

**Giải pháp:**
Check DioProvider interceptor:
```dart
// lib/core/api/dio_provider.dart
class DioProvider {
  Dio get instance {
    final token = TokenStorage.getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return _dio;
  }
}
```

---

## 🔧 Debug Steps (Tuần tự)

### Step 1: Enable Debug Logging
✅ Đã thêm vào code:
- `event_participants_screen.dart` - Log event info và errors
- `club_admin_repository.dart` - Log API response
- `event_api.dart` - Log request/response

### Step 2: Test với Flutter Debug Console

1. Mở VS Code Debug Console
2. Navigate vào màn hình participants
3. Xem console logs:

```
🔍 Loading participants for event: 123
🔍 Event title: Workshop AI
🔍 Event club: Tech Club
[EventApi] GET /api/events/123/participants/
[EventApi] response 200 http://192.168.1.105:8000/api/events/123/participants/
📡 getEventParticipants result: status=200
📡 Response body type: _Map<String, dynamic>
✅ Parsed 15 participants from results
✅ Loaded 15 participants
```

**Nếu thấy:**
```
[EventApi] DioException: type=response status=403
❌ Error response: {"detail": "You do not have permission to perform this action."}
📡 getEventParticipants result: status=403
❌ Throwing exception: You do not have permission to perform this action.
```
→ **Đây là PERMISSION ERROR** (xem giải pháp #1)

### Step 3: Test Backend Permission

Dùng Postman hoặc curl:

```bash
# Get token first
curl -X POST http://192.168.1.105:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"your_username","password":"your_password"}'

# Test participants endpoint
curl -X GET http://192.168.1.105:8000/api/events/123/participants/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response (Success):**
```json
{
  "results": [
    {
      "id": 1,
      "user": {
        "id": 10,
        "username": "student1",
        "email": "student1@example.com"
      },
      "event": 123,
      "status": "registered",
      "registered_at": "2025-11-15T10:00:00Z"
    }
  ]
}
```

**Expected Response (Permission Error):**
```json
{
  "detail": "You do not have permission to perform this action."
}
```
→ Nếu thấy response này → Backend permission chưa đúng

### Step 4: Verify User Permissions

Test trong Flutter app:

```dart
// Thêm vào EventParticipantsScreen initState
@override
void initState() {
  super.initState();
  
  // Debug user permissions
  final auth = Provider.of<AuthService>(context, listen: false);
  final user = auth.user;
  
  debugPrint('👤 Current user: ${user?.username}');
  debugPrint('👤 User role: ${user?.role}');
  debugPrint('👤 Club role: ${user?.profile.clubRole}');
  debugPrint('👤 Is club leader: ${user?.isClubLeader}');
  debugPrint('👤 Can view participants: ${user?.canViewParticipants}');
  debugPrint('👤 Has club admin permission: ${user?.hasClubAdminPermission}');
  
  _loadParticipants();
}
```

**Expected Output (Club Admin):**
```
👤 Current user: club_admin1
👤 User role: club_admin
👤 Club role: admin
👤 Is club leader: true
👤 Can view participants: true
👤 Has club admin permission: true
```

**If you see:**
```
👤 Current user: club_admin1
👤 User role: club_admin
👤 Club role: null                    ← ⚠️ PROBLEM: Backend chưa trả club_role
👤 Is club leader: false              ← ⚠️ PROBLEM: Không có ClubMembership
👤 Can view participants: true        ← ✅ OK: Fallback to User.role
👤 Has club admin permission: true    ← ✅ OK: Fallback to User.role
```
→ Frontend OK, nhưng **backend chưa trả `club_role`**

**If you see:**
```
👤 Current user: student1
👤 User role: student                 ← ⚠️ PROBLEM: User role = student
👤 Club role: null
👤 Is club leader: false
👤 Can view participants: false       ← ❌ PROBLEM: Không có permission
👤 Has club admin permission: false
```
→ User này **không phải club admin**, cần đổi role hoặc tạo ClubMembership

---

## ✅ Quick Fixes

### Fix 1: Tạo ClubMembership record (Backend)

```python
# Django shell
python manage.py shell

from django.contrib.auth import get_user_model
from clubs.models import Club, ClubMembership

User = get_user_model()

# Get user and club
user = User.objects.get(username='club_admin1')
club = Club.objects.get(name='Tech Club')

# Create membership
ClubMembership.objects.get_or_create(
    user=user,
    club=club,
    defaults={
        'role': 'admin',  # or 'president'
        'joined_date': timezone.now()
    }
)
```

### Fix 2: Update Backend Permission Class

```python
# permissions.py
class CanViewParticipants(permissions.BasePermission):
    def has_permission(self, request, view):
        # System admin can view all
        if request.user.role == 'system_admin':
            return True
        
        # Get event from view
        event_id = view.kwargs.get('pk')
        if not event_id:
            return False
        
        try:
            event = Event.objects.get(id=event_id)
            club = event.club
        except Event.DoesNotExist:
            return False
        
        # Check ClubMembership (priority)
        membership = ClubMembership.objects.filter(
            user=request.user,
            club=club,
            role__in=['president', 'admin']
        ).exists()
        
        if membership:
            return True
        
        # Fallback to User.role
        if request.user.role == 'club_admin':
            # Also check if user belongs to this club
            profile = request.user.profile
            if profile.clubName == club.name:
                return True
        
        return False
```

### Fix 3: Hot Reload App

```bash
# In terminal
r  # Hot reload
# or
R  # Hot restart
```

---

## 📊 Expected Results After Fixes

1. **Console Logs:**
```
🔍 Loading participants for event: 123
[EventApi] GET /api/events/123/participants/
[EventApi] response 200
📡 getEventParticipants result: status=200
✅ Parsed 15 participants from results
✅ Loaded 15 participants
```

2. **Screen Shows:**
- List of participants with name, email, status
- Filter chips working
- No error messages

---

## 📞 Support

Nếu vẫn còn lỗi:
1. Copy toàn bộ debug logs từ console
2. Check backend logs: `tail -f /path/to/django/logs/debug.log`
3. Gửi logs và mô tả chi tiết

Reference:
- `BACKEND_REQUIREMENTS.md` - Backend changes needed
- `CLUB_PERMISSION_BEST_PRACTICE.md` - Permission system guide
- `FRONTEND_HELPER_METHODS_UPDATE.md` - Frontend helper methods
