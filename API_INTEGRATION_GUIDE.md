# API Integration Guide - Event Management

## ✅ Đã Hoàn Thành

### 1. **Event API** (`lib/features/event_management/data/api/event_api.dart`)
Đã tạo `EventApi` class với các method:
- ✅ `getAllEvents()` - GET /api/events/
- ✅ `getEventById(id)` - GET /api/events/{id}/
- ✅ `getFeaturedEvents()` - GET /api/events/featured/
- ✅ `searchEvents(query)` - GET /api/events/search/?q={query}
- ✅ `filterEventsByCategory(category)` - GET /api/events/?category={category} **[FIXED]**
- ✅ `registerForEvent(eventId)` - POST /api/events/{id}/register/
- ✅ `unregisterFromEvent(eventId)` - POST /api/events/{id}/unregister/
- ✅ `getMyRegisteredEvents()` - GET /api/registrations/my-events/
- ✅ `submitFeedback(eventId, feedbackData)` - POST /api/events/{id}/feedback/
- ✅ `getEventFeedbacks(eventId)` - GET /api/events/{id}/feedbacks/

### 1.1 **Notification API** (`lib/core/api/notification_api.dart`) 🆕
- ✅ `getNotifications()` - GET /api/notifications/
- ✅ `markAsRead(id)` - POST /api/notifications/{id}/read/
- ✅ `getUnreadCount()` - GET /api/notifications/unread-count/
- ✅ `markAllAsRead()` - POST /api/notifications/mark-all-read/

### 1.2 **Club API** (`lib/core/api/club_api.dart`) 🆕
- ✅ `getAllClubs()` - GET /api/clubs/
- ✅ `getClubById(id)` - GET /api/clubs/{id}/
- ✅ `createClub(data)` - POST /api/clubs/
- ✅ `updateClub(id, data)` - PUT /api/clubs/{id}/
- ✅ `createEvent(clubId, data)` - POST /api/clubs/{clubId}/events/
- ✅ `getClubEvents(clubId)` - GET /api/clubs/{clubId}/events/

### 1.3 **Admin API** (`lib/core/api/admin_api.dart`) 🆕
- ✅ `getStats()` - GET /api/admin/stats/
- ✅ `getActivities()` - GET /api/admin/activities/
- ✅ `getUsers()` - GET /api/admin/users/
- ✅ `updateUserRole(id, role)` - PUT /api/admin/users/{id}/
- ✅ `deleteUser(id)` - DELETE /api/admin/users/{id}/

### 1.4 **Approval API** (`lib/core/api/approval_api.dart`) 🆕
- ✅ `getPendingApprovals()` - GET /api/approvals/pending/
- ✅ `approveEvent(id, comment)` - POST /api/approvals/{id}/approve/
- ✅ `rejectEvent(id, comment)` - POST /api/approvals/{id}/reject/
- ✅ `getApprovalHistory()` - GET /api/approvals/history/

### 2. **Repository Layer** (`lib/features/event_management/data/repositories/event_repository.dart`)
Đã tạo `EventRepository` để xử lý business logic và data transformation.

### 3. **Service Layer** (`lib/features/event_management/domain/services/event_service.dart`)
Đã tạo `EventService` extends `ChangeNotifier` để:
- Quản lý state (loading, error, data)
- Cung cấp các method tiện lợi
- Tự động notify UI khi data thay đổi

### 4. **Integration với Provider**
Đã cập nhật `main.dart` để inject `EventService` vào widget tree.

### 5. **Cập nhật UI Screens**
Đã thay thế `DummyData` bằng API trong:
- ✅ `home_screen.dart` - Sử dụng EventService
- ✅ `explore_screen.dart` - Sử dụng EventService  
- ✅ `my_events_screen.dart` - Sử dụng EventService

---

## 🔧 Cách Sử Dụng

### **Trong Widget:**

```dart
// 1. Watch EventService để tự động rebuild khi data thay đổi
final eventService = context.watch<EventService>();

// 2. Sử dụng data
final events = eventService.allEvents;
final isLoading = eventService.isLoading;
final error = eventService.error;

// 3. Call API methods
context.read<EventService>().loadAllEvents();
context.read<EventService>().registerForEvent('event-id');
```

### **Load Data:**

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final eventService = context.read<EventService>();
    eventService.loadAllEvents();
    eventService.loadFeaturedEvents();
  });
}
```

### **Pull to Refresh:**

```dart
RefreshIndicator(
  onRefresh: () => context.read<EventService>().loadAllEvents(),
  child: ListView(...),
)
```

---

## 🌐 Backend API Requirements

Backend cần implement các endpoints sau:

### **Events:**
```
GET    /api/events/                    # Lấy tất cả events
GET    /api/events/{id}/               # Chi tiết event
GET    /api/events/featured/           # Events nổi bật
GET    /api/events/search/?q={query}   # Tìm kiếm
GET    /api/events/filter/?category={} # Lọc theo category
```

### **Registrations:**
```
POST   /api/events/{id}/register/      # Đăng ký event
POST   /api/events/{id}/unregister/    # Hủy đăng ký
GET    /api/registrations/my-events/   # Events đã đăng ký
```

### **Feedbacks:**
```
POST   /api/events/{id}/feedback/      # Gửi feedback
GET    /api/events/{id}/feedbacks/     # Lấy feedbacks
```

---

## 📋 Response Format

### **Event Object:**
```json
{
  "id": "1",
  "title": "Event Title",
  "description": "Event description",
  "imageUrl": "https://...",
  "date": "2025-11-15T10:00:00Z",
  "startAt": "2025-11-15T10:00:00Z",
  "endAt": "2025-11-15T12:00:00Z",
  "location": "Location name",
  "locationDetail": "Detailed address",
  "category": "Công nghệ",
  "isFeatured": true,
  "clubName": "Tech Club",
  "clubId": "1",
  "capacity": 100,
  "participantCount": 45,
  "status": "approved",
  "posterUrl": "https://...",
  "riskLevel": "low"
}
```

### **List Response:**
```json
[
  { "id": "1", "title": "Event 1", ... },
  { "id": "2", "title": "Event 2", ... }
]
```

---

## 🔐 Authentication

API requests tự động include access token thông qua `TokenInterceptor`:
```dart
Authorization: Bearer <access_token>
```

Token được refresh tự động khi hết hạn.

---

## ⚙️ Configuration

Cập nhật base URL trong `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://YOUR_BACKEND_URL/';
}
```

**Lưu ý:**
- Android Emulator: `http://10.0.2.2:8000/`
- iOS Simulator: `http://localhost:8000/`
- Real Device: `http://YOUR_IP_ADDRESS:8000/`

---

## 🐛 Error Handling

EventService tự động xử lý errors:

```dart
if (eventService.error != null) {
  // Hiển thị error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(eventService.error!)),
  );
}
```

---

## 🎯 Next Steps

### **Để hoàn thiện tích hợp API:**

1. **Setup Backend Django:**
   - Tạo Django REST API với các endpoints trên
   - Implement JWT authentication
   - Enable CORS

2. **Testing:**
   - Test từng API endpoint với Postman
   - Verify response format
   - Test error cases

3. **Additional Features:**
   - Implement pagination cho danh sách events
   - Add image upload cho poster
   - Implement real-time notifications
   - Add caching với shared_preferences

4. **Optimization:**
   - Add debouncing cho search
   - Implement infinite scroll
   - Cache images với cached_network_image
   - Add offline support

---

## 📝 Example: Complete Flow

```dart
// 1. User mở app
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<EventService>().loadAllEvents();
  });
}

// 2. Display events
Widget build(BuildContext context) {
  final eventService = context.watch<EventService>();
  
  if (eventService.isLoading) {
    return CircularProgressIndicator();
  }
  
  if (eventService.error != null) {
    return Text('Error: ${eventService.error}');
  }
  
  return ListView.builder(
    itemCount: eventService.allEvents.length,
    itemBuilder: (context, index) {
      final event = eventService.allEvents[index];
      return EventCard(event: event);
    },
  );
}

// 3. User đăng ký event
onPressed: () async {
  final success = await context.read<EventService>()
      .registerForEvent(event.id);
  
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đăng ký thành công!')),
    );
  }
}
```

---

## ✨ Benefits

✅ **Separation of Concerns** - API, Repository, Service tách biệt
✅ **Type Safety** - Sử dụng models đã định nghĩa
✅ **State Management** - Provider tự động notify UI
✅ **Error Handling** - Centralized error handling
✅ **Loading States** - Built-in loading indicators
✅ **Refresh Support** - Pull-to-refresh enabled
✅ **Scalability** - Dễ dàng thêm endpoints mới

---

Cập nhật: ${new Date().toLocaleDateString()}
