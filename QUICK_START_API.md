# 🚀 Quick Start: Testing API Integration

## ⚡ Trước khi chạy app

### 1. Cấu hình Base URL
Mở `lib/core/config/app_config.dart` và cập nhật URL backend:

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://10.0.2.2:8000/'; // Android Emulator
  // hoặc
  static const String apiBaseUrl = 'http://192.168.1.100:8000/'; // Real Device
}
```

### 2. Khởi động Backend
Đảm bảo Django backend đang chạy:
```bash
python manage.py runserver 0.0.0.0:8000
```

### 3. Chạy Flutter App
```bash
flutter run
```

---

## 🧪 Test Checklist

### ✅ Authentication (Đã có backend)
- [ ] Đăng ký tài khoản mới
- [ ] Đăng nhập
- [ ] Xem thông tin user
- [ ] Đăng xuất

### 🎯 Events (Cần backend)
- [ ] **Home Screen:**
  - [ ] Load danh sách events
  - [ ] Hiển thị featured events
  - [ ] Pull to refresh
  - [ ] Filter theo category
  - [ ] Loading indicator

- [ ] **Explore Screen:**
  - [ ] Load tất cả events
  - [ ] Search events
  - [ ] Filter theo category
  - [ ] Grid/List view toggle

- [ ] **My Events Screen:**
  - [ ] Load events đã đăng ký
  - [ ] Tab Upcoming/Past/Saved
  - [ ] Pull to refresh

- [ ] **Event Detail:**
  - [ ] Đăng ký event
  - [ ] Hủy đăng ký
  - [ ] Gửi feedback

---

## 🐛 Common Issues & Solutions

### Issue 1: Connection Refused
```
DioException [connection error]: The connection errored
```
**Solution:**
- Kiểm tra backend đang chạy
- Kiểm tra URL đúng (Android emulator dùng `10.0.2.2`)
- Tắt firewall/antivirus

### Issue 2: 404 Not Found
```
status=404
```
**Solution:**
- Backend chưa implement endpoint
- Kiểm tra URL path đúng format
- Xem Django logs

### Issue 3: 401 Unauthorized
```
status=401
```
**Solution:**
- Token hết hạn
- Chưa đăng nhập
- Thử logout và login lại

### Issue 4: Empty List
```
Events: []
```
**Solution:**
- Backend chưa có data
- Tạo sample events trong Django admin
- Check response format đúng

---

## 📱 Mock API Testing (Tạm thời)

Nếu backend chưa sẵn sàng, có thể test với mock API:

### Option 1: JSON Placeholder
```dart
// Trong app_config.dart
static const String apiBaseUrl = 'https://jsonplaceholder.typicode.com/';
```

### Option 2: Mock Server Local
Dùng `json-server`:
```bash
npm install -g json-server
json-server --watch db.json --port 8000
```

### Option 3: Giữ DummyData (Fallback)
Thêm fallback trong EventService:
```dart
Future<void> loadAllEvents() async {
  try {
    _allEvents = await repository.getAllEvents();
  } catch (e) {
    // Fallback to dummy data
    _allEvents = DummyData.events;
  }
}
```

---

## 📊 API Response Format

Đảm bảo backend trả về đúng format:

### ✅ Correct Format:
```json
[
  {
    "id": "1",
    "title": "Event Title",
    "date": "2025-11-15T10:00:00Z",
    "category": "Công nghệ",
    "isFeatured": true
  }
]
```

### ❌ Wrong Format:
```json
{
  "results": [...],  // Không cần wrap trong object
  "count": 10
}
```

---

## 🔍 Debug Tips

### 1. Xem API Logs
Check debug prints trong console:
```
[EventApi] GET /api/events/
[EventApi] response 200 http://...
```

### 2. Kiểm tra Network Traffic
Dùng Charles Proxy hoặc Proxyman

### 3. Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### 4. Backend Logs
```bash
# Django
tail -f logs/debug.log

# Print request trong view
print(f"Request: {request.method} {request.path}")
print(f"Data: {request.data}")
```

---

## 🎬 Demo Flow

### Test đầy đủ flow:
1. **Mở app** → Login
2. **Home Screen** → Xem events load từ API
3. **Pull down** → Refresh data
4. **Tap category** → Filter events
5. **Tap event** → Xem detail
6. **Tap "Đăng ký"** → Register event
7. **Go to My Events** → Xem event vừa đăng ký
8. **Tab Past** → Xem events đã qua
9. **Explore Screen** → Search events
10. **Submit feedback** → Gửi đánh giá

---

## 📦 Backend Setup (Django)

Nếu cần setup backend nhanh:

```python
# events/views.py
from rest_framework import viewsets
from .models import Event
from .serializers import EventSerializer

class EventViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    
    @action(detail=False, methods=['get'])
    def featured(self, request):
        featured = self.queryset.filter(is_featured=True)
        serializer = self.get_serializer(featured, many=True)
        return Response(serializer.data)
```

```python
# urls.py
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'events', EventViewSet)

urlpatterns = [
    path('api/', include(router.urls)),
]
```

---

## ✅ Success Indicators

Khi tất cả hoạt động đúng:
- ✅ No console errors
- ✅ Events load và hiển thị
- ✅ Pull to refresh hoạt động
- ✅ Filter theo category hoạt động
- ✅ Đăng ký event thành công
- ✅ My Events hiển thị events đã đăng ký

---

Cần hỗ trợ thêm? Check: `API_INTEGRATION_GUIDE.md`
