# 📋 API Comparison Report - Backend vs Frontend

**Generated**: November 10, 2025  
**Purpose**: So sánh giữa Backend APIs đã implement và Frontend API Integration

---

## ✅ HOÀN TOÀN TƯƠNG THÍCH

### 1. Authentication APIs
| Endpoint | Backend | Frontend | Status |
|----------|---------|----------|--------|
| POST /api/accounts/token/ | ✅ | ✅ | 🟢 Perfect Match |
| POST /api/accounts/token/refresh/ | ✅ | ✅ | 🟢 Perfect Match |
| GET /api/accounts/me/ | ✅ | ✅ | 🟢 Perfect Match |
| POST /api/accounts/logout/ | ✅ | ✅ | 🟢 Perfect Match |
| POST /api/accounts/register/ | ✅ | ✅ | 🟢 Perfect Match |

### 2. Event Management APIs
| Endpoint | Backend | Frontend | Status |
|----------|---------|----------|--------|
| GET /api/events/ | ✅ | ✅ `getAllEvents()` | 🟢 Perfect Match |
| GET /api/events/{id}/ | ✅ | ✅ `getEventById()` | 🟢 Perfect Match |
| POST /api/events/{id}/register/ | ✅ | ✅ `registerForEvent()` | 🟢 Perfect Match |
| POST /api/events/{id}/unregister/ | ✅ | ✅ `unregisterFromEvent()` | 🟢 Perfect Match |
| GET /api/registrations/my-events/ | ✅ | ✅ `getMyRegisteredEvents()` | 🟢 Perfect Match |

### 3. Feedback APIs
| Endpoint | Backend | Frontend | Status |
|----------|---------|----------|--------|
| POST /api/events/{id}/feedback/ | ✅ | ✅ `submitFeedback()` | 🟢 Perfect Match |
| GET /api/events/{id}/feedbacks/ | ✅ | ✅ `getEventFeedbacks()` | 🟢 Perfect Match |

---

## ⚠️ CẦN ĐIỀU CHỈNH

### 1. Featured Events Endpoint
**Backend**: `GET /api/events/featured/` (custom action)  
**Frontend**: `GET /api/events/featured/` ✅  
**Status**: 🟢 **Compatible** - Backend có endpoint này

**Fix Frontend**: Không cần sửa, đã đúng!

### 2. Search Events Endpoint
**Backend**: `GET /api/events/search/?q={query}` ✅  
**Frontend**: `GET /api/events/search/?q={query}` ✅  
**Status**: 🟢 **Perfect Match**

### 3. Filter by Category
**Backend**: `GET /api/events/?category={category}` (query param)  
**Frontend**: `GET /api/events/filter/?category={category}` ❌  
**Status**: 🟡 **Needs Fix**

**Giải pháp**:

#### Option 1: Sửa Frontend (Khuyến nghị)
```dart
// Trong event_api.dart
Future<Map<String, dynamic>> filterEventsByCategory(String category) async {
  _dbg('GET /api/events/?category=$category');
  try {
    final res = await dio.get('/api/events/', queryParameters: {'category': category});
    // ...
  }
}
```

#### Option 2: Thêm Backend endpoint (Không cần thiết)
```python
# Trong event_management/views.py - EventViewSet
@action(detail=False, methods=['get'])
def filter(self, request):
    category = request.query_params.get('category')
    queryset = self.get_queryset().filter(category=category)
    serializer = self.get_serializer(queryset, many=True)
    return Response(serializer.data)
```

---

## 🆕 BACKEND CÓ THÊM (Frontend chưa dùng)

### 1. Club Management
**Backend có**:
- GET /api/clubs/
- GET /api/clubs/{id}/
- POST /api/clubs/
- POST /api/clubs/{club_id}/events/

**Frontend**: Chưa implement

**Khuyến nghị**: Tạo `ClubApi` và `ClubService` tương tự EventService

### 2. Event Management (Club Admin)
**Backend có**:
- PUT /api/events/{id}/
- GET /api/events/{id}/participants/
- POST /api/events/{id}/upload-poster/

**Frontend**: Chưa implement

**Khuyến nghị**: Thêm vào EventApi khi cần tính năng quản lý event

### 3. Approval System
**Backend có**:
- GET /api/approvals/pending/
- POST /api/approvals/{event_id}/approve/
- POST /api/approvals/{event_id}/reject/

**Frontend**: Chưa implement

**Khuyến nghị**: Tạo `ApprovalApi` cho admin screen

### 4. Admin Dashboard
**Backend có**:
- GET /api/admin/stats/
- GET /api/admin/activities/
- GET /api/admin/users/

**Frontend**: Chưa implement

**Khuyến nghị**: Tạo `AdminApi` cho dashboard

### 5. Notifications
**Backend có**:
- GET /api/notifications/
- POST /api/notifications/{id}/read/
- GET /api/notifications/unread-count/
- POST /api/notifications/mark-all-read/

**Frontend**: Chưa implement

**Khuyến nghị**: Tạo `NotificationApi` và `NotificationService`

---

## 🎯 ACTION ITEMS

### 🔴 CRITICAL (Cần fix ngay)

#### 1. Fix Filter Endpoint
```dart
// File: lib/features/event_management/data/api/event_api.dart
// Line: ~82

// ❌ CŨ:
Future<Map<String, dynamic>> filterEventsByCategory(String category) async {
  _dbg('GET /api/events/filter/?category=$category');
  final res = await dio.get('/api/events/filter/', queryParameters: {'category': category});
}

// ✅ MỚI:
Future<Map<String, dynamic>> filterEventsByCategory(String category) async {
  _dbg('GET /api/events/?category=$category');
  final res = await dio.get('/api/events/', queryParameters: {'category': category});
}
```

### 🟡 MEDIUM (Nên làm)

#### 2. Thêm Club Management API
```dart
// Tạo file mới: lib/features/club_management/data/api/club_api.dart
class ClubApi {
  final Dio dio;
  ClubApi({Dio? dio}) : dio = dio ?? Dio();

  Future<Map<String, dynamic>> getAllClubs() async {
    final res = await dio.get('/api/clubs/');
    return {'status': res.statusCode, 'body': res.data};
  }

  Future<Map<String, dynamic>> getClubById(String id) async {
    final res = await dio.get('/api/clubs/$id/');
    return {'status': res.statusCode, 'body': res.data};
  }

  Future<Map<String, dynamic>> createEvent(String clubId, Map<String, dynamic> eventData) async {
    final res = await dio.post('/api/clubs/$clubId/events/', data: eventData);
    return {'status': res.statusCode, 'body': res.data};
  }
}
```

#### 3. Thêm Notification API
```dart
// Tạo file: lib/features/notifications/data/api/notification_api.dart
class NotificationApi {
  final Dio dio;
  NotificationApi({Dio? dio}) : dio = dio ?? Dio();

  Future<Map<String, dynamic>> getNotifications() async {
    final res = await dio.get('/api/notifications/');
    return {'status': res.statusCode, 'body': res.data};
  }

  Future<Map<String, dynamic>> markAsRead(String id) async {
    final res = await dio.post('/api/notifications/$id/read/');
    return {'status': res.statusCode, 'body': res.data};
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    final res = await dio.get('/api/notifications/unread-count/');
    return {'status': res.statusCode, 'body': res.data};
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    final res = await dio.post('/api/notifications/mark-all-read/');
    return {'status': res.statusCode, 'body': res.data};
  }
}
```

### 🟢 LOW (Có thể làm sau)

#### 4. Thêm Admin APIs
- Admin stats
- Admin activities
- User management

#### 5. Thêm Event Management (Club Admin)
- Update event
- View participants
- Upload poster

---

## 📈 COMPATIBILITY SCORE

| Category | Compatible | Total | Score |
|----------|-----------|-------|-------|
| **Authentication** | 5/5 | 5 | 🟢 100% |
| **Event Management** | 5/5 | 5 | 🟢 100% |
| **Feedback** | 2/2 | 2 | 🟢 100% |
| **Featured Events** | 1/1 | 1 | 🟢 100% |
| **Search** | 1/1 | 1 | 🟢 100% |
| **Filter** | 0/1 | 1 | 🔴 0% (Needs Fix) |
| **Overall Core APIs** | 14/15 | 15 | 🟡 93% |

---

## 🎯 RECOMMENDED FIXES (Theo thứ tự ưu tiên)

### Priority 1: Fix Filter Endpoint (5 phút)
```bash
# Sửa file: event_api.dart dòng ~82
# Đổi '/api/events/filter/' → '/api/events/'
```

### Priority 2: Test toàn bộ flow (30 phút)
1. Đăng ký user
2. Đăng nhập
3. Xem danh sách events
4. Filter theo category
5. Search events
6. Đăng ký event
7. Submit feedback

### Priority 3: Thêm Notification API (1 giờ)
Để hiển thị thông báo trong UI

### Priority 4: Thêm Club Management (2 giờ)
Để Club Admin có thể tạo event

### Priority 5: Thêm Admin APIs (2 giờ)
Để Admin có dashboard đầy đủ

---

## 📝 SUMMARY

### ✅ What's Working
- Authentication flow hoàn hảo
- Event listing, detail, search
- Event registration/unregistration
- Feedback system
- My registered events

### ⚠️ What Needs Fixing
- **Filter endpoint URL** (Critical - 5 phút fix)

### 🆕 What's Missing (Optional)
- Club Management APIs
- Notification APIs
- Admin Dashboard APIs
- Event Management (for Club Admin)

### 🎉 Overall Assessment
**93% compatible** - Rất tốt! Chỉ cần fix 1 endpoint là frontend sẽ hoạt động hoàn hảo với backend.

---

## 🚀 Quick Fix Script

Chạy lệnh sau để tự động fix filter endpoint:

```bash
# Windows PowerShell
(Get-Content "lib\features\event_management\data\api\event_api.dart") -replace "/api/events/filter/", "/api/events/" | Set-Content "lib\features\event_management\data\api\event_api.dart"
```

Hoặc sửa thủ công:
1. Mở `lib/features/event_management/data/api/event_api.dart`
2. Tìm dòng ~82: `await dio.get('/api/events/filter/'`
3. Đổi thành: `await dio.get('/api/events/'`
4. Save

---

**Kết luận**: Backend và Frontend của bạn tương thích rất cao! Chỉ cần fix 1 endpoint nhỏ là có thể chạy ngay. 🎉
