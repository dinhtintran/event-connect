# 🔔 Hệ Thống Thông Báo Event Connect

## 📋 Tổng Quan

Hệ thống thông báo tự động cho cả 3 loại người dùng:
- **Students**: Thông báo về sự kiện, đăng ký, nhắc nhở
- **Club Admins**: Thông báo về quản lý sự kiện, đăng ký mới, feedback
- **System Admins**: Thông báo về phê duyệt, cảnh báo, báo cáo hệ thống

---

## 🎯 Loại Thông Báo

### 1. STUDENT NOTIFICATIONS

| Type | Khi nào gửi | Nội dung |
|------|-------------|----------|
| `registration_confirmed` | Sau khi đăng ký sự kiện | "Bạn đã đăng ký thành công sự kiện X" |
| `event_reminder` | 3 ngày trước sự kiện | "Sự kiện X sẽ diễn ra trong 3 ngày nữa" |
| `event_updated` | Khi sự kiện được cập nhật | "Sự kiện X đã có thông tin mới" |
| `event_cancelled` | Khi sự kiện bị hủy | "Sự kiện X đã bị hủy" |
| `event_approved` | Khi sự kiện của club được duyệt | "Sự kiện mới X từ club Y đã sẵn sàng" |
| `feedback_request` | 1 ngày sau sự kiện kết thúc | "Hãy đánh giá sự kiện X" |

### 2. CLUB ADMIN NOTIFICATIONS

| Type | Khi nào gửi | Nội dung |
|------|-------------|----------|
| `event_approved` | Khi sự kiện được phê duyệt | "Sự kiện X đã được phê duyệt" |
| `event_rejected` | Khi sự kiện bị từ chối | "Sự kiện X bị từ chối. Lý do: ..." |
| `new_registration` | Khi có người đăng ký mới | "User Y đã đăng ký sự kiện X" |
| `event_full` | Khi sự kiện đã đầy | "Sự kiện X đã đạt đủ số lượng" |
| `feedback_received` | Khi nhận feedback mới | "User Y đã gửi feedback cho sự kiện X" |
| `low_attendance` | Khi tỷ lệ tham dự thấp | "Sự kiện X có tỷ lệ tham dự thấp" |

### 3. SYSTEM ADMIN NOTIFICATIONS

| Type | Khi nào gửi | Nội dung |
|------|-------------|----------|
| `event_pending` | Khi có sự kiện mới cần duyệt | "Sự kiện X đang chờ phê duyệt" |
| `high_risk_event` | Khi phát hiện sự kiện rủi ro cao | "Sự kiện X có nguy cơ cao" |
| `club_violation` | Khi club vi phạm quy định | "Club X có hành vi vi phạm" |
| `system_issue` | Khi có vấn đề hệ thống | "Vấn đề: ..." |
| `system_stats` | Báo cáo định kỳ | "Báo cáo tuần/tháng" |

---

## 🚀 API Endpoints

### 1. Lấy danh sách notifications

```bash
GET /api/notifications/notifications/
Authorization: Bearer <access_token>

# Params
?is_read=false  # Chỉ lấy chưa đọc
?page=1         # Phân trang
```

**Response:**
```json
{
  "count": 5,
  "unread_count": 5,
  "results": [
    {
      "id": 7,
      "type": "feedback_request",
      "title": "Đánh giá sự kiện",
      "message": "Bạn đã tham dự AI Workshop...",
      "event": {"id": 3, "title": "AI Workshop - Basic"},
      "club": null,
      "is_read": false,
      "read_at": null,
      "created_at": "2025-12-21T14:09:10.851603Z"
    }
  ]
}
```

### 2. Lấy số lượng chưa đọc

```bash
GET /api/notifications/notifications/unread_count/
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "unread_count": 5
}
```

### 3. Đánh dấu đã đọc

```bash
POST /api/notifications/notifications/{id}/read/
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "message": "Notification marked as read",
  "notification_id": 7
}
```

### 4. Đánh dấu tất cả đã đọc

```bash
POST /api/notifications/notifications/mark_all_read/
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "message": "Marked 5 notifications as read",
  "count": 5
}
```

---

## 💻 Sử Dụng NotificationService trong Code

### Import Service

```python
from notifications.services import NotificationService
```

### Tạo notification thủ công

```python
# Tạo notification cho user
NotificationService.create_notification(
    user=user,
    notification_type='custom_type',
    title='Tiêu đề',
    message='Nội dung thông báo',
    event=event,  # Optional
    club=club     # Optional
)
```

### Gửi notification tự động

```python
# Khi user đăng ký event
NotificationService.notify_registration_confirmed(user, event)
NotificationService.notify_new_registration(event, user)

# Khi event được approve
NotificationService.notify_event_approval_status(event, 'approved', reviewer)
NotificationService.notify_event_approved_to_followers(event)

# Khi event bị reject
NotificationService.notify_event_approval_status(event, 'rejected', reviewer, comment)

# Khi event mới cần approve
NotificationService.notify_new_event_pending(event)
```

### Log activity

```python
NotificationService.log_activity(
    user=request.user,
    action='event_created',
    description=f'Created event: {event.title}',
    metadata={'event_id': event.id}
)
```

---

## ⚙️ Management Commands

### Gửi notifications tự động (cronjob)

```bash
# Gửi tất cả
python manage.py send_notifications

# Chỉ gửi reminders
python manage.py send_notifications --type=reminders

# Chỉ gửi feedback requests
python manage.py send_notifications --type=feedback
```

### Setup cronjob

Thêm vào crontab:

```bash
# Gửi reminders mỗi ngày lúc 9:00 AM
0 9 * * * cd /path/to/backend && source venv/bin/activate && python manage.py send_notifications --type=reminders

# Gửi feedback requests mỗi ngày lúc 10:00 AM
0 10 * * * cd /path/to/backend && source venv/bin/activate && python manage.py send_notifications --type=feedback
```

---

## 🧪 Testing

### 1. Tạo notifications mẫu

```bash
cd event_connect_backend
source venv/bin/activate
python create_sample_notifications.py
```

### 2. Test API với curl

```bash
# Login để lấy token
TOKEN=$(curl -s -X POST http://127.0.0.1:8000/api/accounts/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"student1","password":"student123"}' | python3 -c "import sys, json; print(json.load(sys.stdin)['access'])")

# Lấy notifications
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8000/api/notifications/notifications/

# Lấy unread count
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8000/api/notifications/notifications/unread_count/

# Mark as read
curl -X POST -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8000/api/notifications/notifications/1/read/
```

---

## 📱 Flutter Integration

### 1. Get Notifications

```dart
final notificationApi = NotificationApi();
final accessToken = await TokenStorage().readAccess();

final result = await notificationApi.getNotifications(
  accessToken: accessToken!,
  isRead: false,  // Chỉ lấy chưa đọc
  page: 1,
);

if (result['status'] == 200) {
  final notifications = result['body']['results'];
  final unreadCount = result['body']['unread_count'];
}
```

### 2. Mark as Read

```dart
final result = await notificationApi.markAsRead(
  accessToken: accessToken!,
  notificationId: '7',
);
```

### 3. Get Unread Count

```dart
final result = await notificationApi.getUnreadCount(
  accessToken: accessToken!,
);

if (result['status'] == 200) {
  final count = result['body']['unread_count'];
}
```

---

## 📊 Database Schema

```sql
CREATE TABLE notifications_notification (
    id INT PRIMARY KEY,
    user_id INT FOREIGN KEY,
    type VARCHAR(50),
    title VARCHAR(255),
    message TEXT,
    event_id INT NULL FOREIGN KEY,
    club_id INT NULL FOREIGN KEY,
    is_read BOOLEAN DEFAULT FALSE,
    read_at DATETIME NULL,
    created_at DATETIME
);

CREATE TABLE notifications_activitylog (
    id INT PRIMARY KEY,
    user_id INT FOREIGN KEY,
    action VARCHAR(100),
    description TEXT,
    metadata JSON,
    created_at DATETIME
);
```

---

## ✅ Checklist Triển Khai

- [x] Backend NotificationService
- [x] API endpoints cho notifications
- [x] Tích hợp tự động gửi notifications
- [x] Management commands
- [x] Sample data script
- [ ] Setup cronjob cho batch notifications
- [ ] Flutter UI notifications screen
- [ ] Real-time notifications (WebSocket/Firebase)
- [ ] Push notifications (FCM)
- [ ] Email notifications

---

## 🔗 Related Files

- `notifications/services.py` - NotificationService
- `notifications/views.py` - API views
- `notifications/models.py` - Models
- `notifications/serializers.py` - Serializers
- `create_sample_notifications.py` - Sample data script
- `notifications/management/commands/send_notifications.py` - Management command

---

**Tạo bởi:** Event Connect Team  
**Ngày cập nhật:** 21/12/2025  
**Version:** 1.0

