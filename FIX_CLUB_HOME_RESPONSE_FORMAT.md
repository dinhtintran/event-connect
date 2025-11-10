# Fix: "Invalid response format" Error - Club Home Page

## 🐛 Vấn Đề

**Error Message:**
```
Error loading club home data: Exception: Invalid response format: Expected List or Map with results/data
```

**Root Cause:**
- ClubHomePage gọi 4 API calls song song với `Future.wait()`
- Một trong các API trả về format không match với expected format
- Error không chỉ rõ API nào gây lỗi → khó debug

## 🔍 APIs Được Gọi

ClubHomePage._loadData() gọi 4 endpoints:

1. **getRecentClubEvents()** - `/api/clubs/{id}/events/` 
   - Expected: `{"results": [...], "count": N}` or `[...]`
   - Parsed by: `_parseEventList()`

2. **getNotifications()** - `/api/notifications/?is_read=false`
   - Expected: `{"results": [...]}` or `[...]`
   - Parsed by: `getNotifications()`

3. **getUnreadNotificationCount()** - `/api/notifications/unread-count/`
   - Expected: `{"unread_count": N}` or `N`
   - Parsed by: `getUnreadNotificationCount()`

4. **getClubInfo()** - `/api/clubs/{id}/`
   - Expected: `{club object}`
   - **ISSUE**: Backend có thể trả về `[{club}]` (array) thay vì object

## ✅ Giải Pháp

### 1. Sequential Loading với Error Isolation

**File:** `club_home_page.dart`

**Thay:**
```dart
final results = await Future.wait([...]);
```

**Bằng:**
```dart
// Fetch sequentially với try-catch riêng cho từng API
List<Event> recentEvents = [];
try {
  debugPrint('Fetching recent events...');
  recentEvents = await _repository.getRecentClubEvents(clubId, limit: 5);
} catch (e) {
  debugPrint('Error fetching recent events: $e');
}

// Tương tự cho 3 API còn lại...
```

**Benefits:**
- ✅ Một API lỗi không crash toàn bộ page
- ✅ Debug logs chỉ rõ API nào fail
- ✅ Partial data vẫn hiển thị được

### 2. Safe Parsing cho getClubInfo()

**File:** `club_admin_repository.dart`

**Thêm:**
```dart
Future<Map<String, dynamic>> getClubInfo(String clubId) async {
  final result = await api.getClubInfo(clubId);
  if (result['status'] == 200) {
    final body = result['body'];
    if (body is Map<String, dynamic>) {
      return body;
    } else if (body is List && body.isNotEmpty) {
      // Backend might return array with single club
      return body[0] as Map<String, dynamic>;
    }
    throw Exception('Invalid response format for club info: ${body.runtimeType}');
  }
  // ...
}
```

**Handles:**
- ✅ `{"id": 1, "name": "..."}` - Single object
- ✅ `[{"id": 1, "name": "..."}]` - Array with object
- ❌ Other formats → Clear error message

## 🧪 Testing

### Verify Fix

1. **Run app với debug logs:**
   ```bash
   flutter run
   ```

2. **Login as club_admin**

3. **Navigate to Club Home**

4. **Check terminal logs:**
   ```
   [ClubHomePage] Fetching recent events...
   [ClubAdminApi] getClubEvents: clubId=1, status=null, search=null
   [EventApi] GET /api/clubs/1/events/
   [EventApi] response 200 http://127.0.0.1:8000/api/clubs/1/events/
   [ClubHomePage] Recent events loaded: 5
   
   [ClubHomePage] Fetching notifications...
   [NotificationApi] GET /api/notifications/
   [NotificationApi] response 200 http://127.0.0.1:8000/api/notifications/
   [ClubHomePage] Notifications loaded: 3
   
   [ClubHomePage] Fetching unread count...
   [NotificationApi] GET /api/notifications/unread-count/
   [NotificationApi] response 200 http://127.0.0.1:8000/api/notifications/unread-count/
   [ClubHomePage] Unread count: 3
   
   [ClubHomePage] Fetching club info...
   [ClubApi] GET /api/clubs/1/
   [ClubApi] response 200 http://127.0.0.1:8000/api/clubs/1/
   [ClubHomePage] Club info loaded: Tech Club
   ```

5. **If error persists:**
   - Check which API log appears last before error
   - Verify backend response format for that endpoint
   - Add more specific handling in repository

### Common Issues

#### Issue 1: Empty Response Array
**Symptom:** `Error fetching recent events: Invalid response format`

**Check:**
```bash
curl http://127.0.0.1:8000/api/clubs/1/events/
```

**Expected:**
```json
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": []
}
```

**Fix:** Backend should always return pagination wrapper

---

#### Issue 2: Club Info as Array
**Symptom:** `Error fetching club info: Invalid response format`

**Check:**
```bash
curl http://127.0.0.1:8000/api/clubs/1/
```

**Response A (correct):**
```json
{
  "id": 1,
  "name": "Tech Club",
  "description": "..."
}
```

**Response B (handled by fix):**
```json
[
  {
    "id": 1,
    "name": "Tech Club",
    "description": "..."
  }
]
```

**Fix:** Repository now handles both formats

---

#### Issue 3: Notification Empty Object
**Symptom:** `Error fetching notifications: type 'int' is not a subtype`

**Check:**
```bash
curl -H "Authorization: Bearer <token>" http://127.0.0.1:8000/api/notifications/?is_read=false
```

**Expected:**
```json
{
  "count": 0,
  "results": []
}
```

**Fix:** Already handled by `getNotifications()` in repository

---

## 📊 Performance Improvement (Optional)

Hiện tại: **Sequential loading** (slower but safer)
- Total time = Sum of all API times
- Example: 200ms + 150ms + 100ms + 180ms = **630ms**

Alternative: **Parallel loading with better error handling**
```dart
final results = await Future.wait([
  _repository.getRecentClubEvents(clubId, limit: 5)
      .catchError((e) { debugPrint('Error: $e'); return <Event>[]; }),
  _repository.getNotifications(isRead: false)
      .catchError((e) { debugPrint('Error: $e'); return <AppNotification>[]; }),
  _repository.getUnreadNotificationCount()
      .catchError((e) { debugPrint('Error: $e'); return 0; }),
  _repository.getClubInfo(clubId)
      .catchError((e) { debugPrint('Error: $e'); return <String, dynamic>{}; }),
]);
```

**Benefits:**
- ⚡ Faster: Total time = Max(API times) = **200ms**
- ✅ Error isolation maintained
- ✅ Partial data still works

**When to use:**
- Production with stable backend
- After all APIs are verified working

---

## 🎯 Summary

**Changes Made:**
1. ✅ Sequential API calls với individual error handling
2. ✅ Debug logs cho mỗi API call
3. ✅ Safe parsing cho club info (handle array or object)
4. ✅ Graceful degradation (partial data on errors)

**Testing Status:**
- ⏳ Pending backend verification
- ⏳ Pending app run with debug logs

**Next Steps:**
1. Run app and check debug logs
2. Identify which API returns unexpected format
3. Update backend or add more format handling
4. Consider switching to parallel loading after stability confirmed
