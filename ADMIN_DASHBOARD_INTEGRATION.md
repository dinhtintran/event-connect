# 📊 Admin Dashboard Integration - Frontend ↔ Backend ↔ Database

## ✅ Hoàn thành kết nối toàn bộ luồng

### 🔄 Luồng dữ liệu (Data Flow)

```
┌─────────────────────┐
│   Admin Dashboard   │  (UI Layer)
│   AdminHomeScreen   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   AdminService      │  (State Management)
│  ChangeNotifier     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  AdminRepository    │  (Data Layer)
│   HTTP API Calls    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Backend Django    │  (API Layer)
│   /api/admin/*      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Database SQLite    │  (Data Storage)
│    db.sqlite3       │
└─────────────────────┘
```

---

## 📍 API Endpoints được tích hợp

### 1. **GET /api/admin/stats/**
- **Mục đích**: Lấy thống kê tổng quan cho dashboard
- **Frontend**: `AdminService.fetchStats()`
- **Backend**: `notifications/views.py` → `admin_stats()`
- **Database queries**:
  ```python
  Event.objects.count()
  User.objects.count()
  Club.objects.count()
  EventRegistration.objects.count()
  ```
- **Response**:
  ```json
  {
    "overview": {
      "total_events": 5,
      "total_users": 8,
      "total_clubs": 3,
      "total_registrations": 8
    },
    "events": {
      "pending": 1,
      "approved": 3,
      "ongoing": 0,
      "completed": 1
    },
    "recent_activity": {...},
    "top_events": [...],
    "top_clubs": [...]
  }
  ```

### 2. **GET /api/approvals/pending/**
- **Mục đích**: Lấy danh sách sự kiện chờ phê duyệt
- **Frontend**: `AdminService.fetchPendingApprovals()`
- **Backend**: `event_management/views.py` → `EventApprovalViewSet.pending()`
- **Database queries**:
  ```python
  EventApproval.objects.filter(status='pending')
    .select_related('event', 'event__club', 'event__created_by')
  ```
- **Response**:
  ```json
  {
    "count": 1,
    "results": [
      {
        "id": 1,
        "event": {
          "id": "4",
          "title": "Career Seminar 2025",
          "description": "...",
          "status": "pending",
          ...
        },
        "status": "pending",
        "submitted_at": "2025-11-10T04:27:48.123Z"
      }
    ]
  }
  ```

### 3. **POST /api/approvals/{event_id}/approve/**
- **Mục đích**: Phê duyệt sự kiện
- **Frontend**: `AdminService.approveEvent(eventId)`
- **Backend**: `event_management/views.py` → `EventApprovalViewSet.approve()`
- **Database operations**:
  ```python
  # Update event status
  event.status = 'approved'
  event.save()
  
  # Update approval record
  approval.status = 'approved'
  approval.reviewer = request.user
  approval.reviewed_at = timezone.now()
  approval.save()
  
  # Create notification
  Notification.objects.create(
    user=event.created_by,
    type='event_approved',
    event=event,
    message=f'Your event "{event.title}" has been approved'
  )
  
  # Log activity
  ActivityLog.objects.create(...)
  ```

### 4. **POST /api/approvals/{event_id}/reject/**
- **Mục đích**: Từ chối sự kiện
- **Frontend**: `AdminService.rejectEvent(eventId, reason)`
- **Backend**: `event_management/views.py` → `EventApprovalViewSet.reject()`
- **Database operations**: Tương tự approve nhưng với status='rejected'

### 5. **GET /api/admin/activities/**
- **Mục đích**: Lấy danh sách hoạt động gần đây
- **Frontend**: `AdminService.fetchActivities()`
- **Backend**: `notifications/views.py` → `admin_activities()`
- **Database queries**:
  ```python
  ActivityLog.objects.select_related('user')
    .order_by('-created_at')[offset:limit]
  ```

---

## 📂 Cấu trúc File Frontend

```
lib/features/admin_dashboard/
├── domain/
│   ├── models/
│   │   ├── admin_stats.dart          ✅ Models cho dashboard stats
│   │   └── activity.dart             (existing)
│   ├── repositories/
│   │   └── admin_repository.dart     ✅ HTTP API calls
│   └── services/
│       └── admin_service.dart        ✅ State management
└── presentation/
    ├── screens/
    │   └── admin_home_screen.dart    ✅ Cập nhật sử dụng real data
    └── widgets/
        ├── stat_card.dart
        ├── pending_event_card.dart
        ├── activity_item.dart
        └── quick_action_button.dart
```

---

## 🔐 Authentication Flow

### Token Management
```dart
// AdminRepository lấy token từ secure storage
final token = await _storage.read(key: 'access_token');

// Gửi kèm header Authorization
headers: {
  'Authorization': 'Bearer $token',
}
```

### Permission Check Backend
```python
@permission_classes([IsSystemAdmin])
def admin_stats(request):
    # Only users with role='system_admin' can access
    ...
```

---

## 🗄️ Database Schema (SQLite)

### Users Table
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  username VARCHAR(150) UNIQUE,
  email VARCHAR(254),
  role VARCHAR(20),  -- 'system_admin', 'club_admin', 'student'
  ...
);
```

### Events Table
```sql
CREATE TABLE events (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255),
  status VARCHAR(20),  -- 'pending', 'approved', 'ongoing', 'completed'
  club_id INTEGER REFERENCES clubs(id),
  created_by_id INTEGER REFERENCES users(id),
  ...
);
```

### Event Approvals Table
```sql
CREATE TABLE event_approvals (
  id INTEGER PRIMARY KEY,
  event_id INTEGER REFERENCES events(id),
  status VARCHAR(20),  -- 'pending', 'approved', 'rejected'
  reviewer_id INTEGER REFERENCES users(id),
  reviewed_at DATETIME,
  comments TEXT,
  ...
);
```

### Activity Logs Table
```sql
CREATE TABLE activity_logs (
  id INTEGER PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  action VARCHAR(50),  -- 'event_created', 'event_approved', etc.
  description TEXT,
  metadata JSON,
  created_at DATETIME,
  ...
);
```

---

## ✨ Các tính năng đã tích hợp

### ✅ Dashboard Statistics
- Hiển thị tổng số sự kiện, người dùng từ database thực
- Cập nhật real-time khi có thay đổi
- Pull-to-refresh với nút refresh button

### ✅ Pending Approvals
- Load danh sách sự kiện chờ phê duyệt từ API
- Approve/Reject với confirmation dialog
- Update UI sau khi thành công
- Hiển thị loading state

### ✅ Recent Activities
- Load activity logs từ database
- Format timestamp thân thiện (2 phút trước, 1 giờ trước, etc.)
- Icon mapping theo loại action

### ✅ Error Handling
- Loading states cho từng section
- Empty states khi không có dữ liệu
- Error messages khi API call thất bại

---

## 🧪 Test với dữ liệu mẫu

Backend đã có dữ liệu mẫu từ `populate_data.py`:

### Admin User
- **Username**: `admin`
- **Password**: `admin123`
- **Role**: `system_admin`

### Sample Data
- ✅ 8 users (1 admin, 2 club admins, 5 students)
- ✅ 3 clubs
- ✅ 5 events (1 pending, 3 approved, 1 completed)
- ✅ 8 registrations
- ✅ 3 feedbacks
- ✅ Activity logs

---

## 🚀 Cách test

### 1. Đăng nhập với admin
```
Username: admin
Password: admin123
```

### 2. Xem Dashboard
- Statistics hiển thị số liệu thật từ database
- Pending events (nếu có)
- Recent activities

### 3. Phê duyệt sự kiện
- Click nút "Phê duyệt" trên sự kiện pending
- Xác nhận → API được gọi
- Database được cập nhật
- UI refresh tự động

### 4. Từ chối sự kiện
- Click nút "Từ chối"
- Nhập lý do
- Xác nhận → API được gọi với reason
- Notification được gửi đến người tạo event

---

## 📊 Database Query Examples

### Lấy thống kê tổng quan
```python
# Backend: notifications/views.py → admin_stats()
overview = {
    'total_events': Event.objects.count(),           # SELECT COUNT(*) FROM events
    'total_users': User.objects.count(),             # SELECT COUNT(*) FROM users
    'total_clubs': Club.objects.count(),             # SELECT COUNT(*) FROM clubs
    'total_registrations': EventRegistration.objects.count()
}
```

### Lấy pending approvals
```python
# Backend: event_management/views.py → pending()
queryset = EventApproval.objects.filter(status='pending')\
    .select_related('event', 'event__club', 'event__created_by')\
    .order_by('-submitted_at')
# SELECT * FROM event_approvals 
# JOIN events ON event_approvals.event_id = events.id
# JOIN clubs ON events.club_id = clubs.id
# JOIN users ON events.created_by_id = users.id
# WHERE event_approvals.status = 'pending'
# ORDER BY event_approvals.submitted_at DESC
```

### Approve event
```python
# Backend: event_management/views.py → approve()
with transaction.atomic():
    # UPDATE events SET status='approved' WHERE id=?
    event.status = 'approved'
    event.save()
    
    # UPDATE event_approvals SET status='approved', reviewer_id=?, reviewed_at=? WHERE event_id=?
    approval.status = 'approved'
    approval.reviewer = request.user
    approval.reviewed_at = timezone.now()
    approval.save()
    
    # INSERT INTO notifications (...) VALUES (...)
    Notification.objects.create(...)
    
    # INSERT INTO activity_logs (...) VALUES (...)
    ActivityLog.objects.create(...)
```

---

## 🎯 Kết luận

Toàn bộ luồng từ **Frontend (Flutter) → Backend (Django) → Database (SQLite)** đã được kết nối đầy đủ và hoạt động:

1. ✅ **UI Layer**: AdminHomeScreen với Consumer<AdminService>
2. ✅ **State Management**: AdminService (ChangeNotifier)
3. ✅ **Data Layer**: AdminRepository (HTTP calls với JWT auth)
4. ✅ **API Layer**: Django REST Framework endpoints
5. ✅ **Database**: SQLite với populate data

**Status**: 🟢 **FULLY INTEGRATED & WORKING**

---

**Ngày tạo**: November 10, 2025  
**Version**: 1.0.0

