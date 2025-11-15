# Hướng dẫn Quản lý và Đăng ký Sự kiện

## Tổng quan

Tính năng Quản lý và Đăng ký Sự kiện cho phép:
- **Club Admin**: Tạo, chỉnh sửa, và quản lý sự kiện của CLB
- **Sinh viên**: Đăng ký tham gia sự kiện, hủy đăng ký
- **Club Admin**: Xem danh sách người đăng ký sự kiện

## 🎯 Các tính năng đã hoàn thiện

### 1. Tạo sự kiện mới (Create Event)
**File**: `lib/features/event_creation/presentation/screens/create_event_screen.dart`

**Chức năng**:
- Form nhập thông tin sự kiện đầy đủ
- Chọn ngày giờ bắt đầu/kết thúc
- Chọn thể loại (8 loại: Học thuật, Thể thao, Văn hóa, Công nghệ, Tình nguyện, Giải trí, Workshop, Khác)
- Đặt sức chứa và các thông tin khác
- Đánh dấu sự kiện nổi bật

**API Endpoint**: `POST /api/events/`

**Cách sử dụng**:
```dart
// Từ ClubEventsPage, nhấn nút "Tạo sự kiện mới"
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CreateEventScreen(clubId: clubId),
  ),
);
```

### 2. Chỉnh sửa sự kiện (Edit Event)
**File**: `lib/features/event_creation/presentation/screens/edit_event_screen.dart`

**Chức năng**:
- Load dữ liệu sự kiện hiện tại vào form
- Cho phép chỉnh sửa tất cả thông tin
- Validate dữ liệu trước khi cập nhật
- Hiển thị thông báo thành công/lỗi

**API Endpoint**: `PUT /api/events/{id}/`

**Cách sử dụng**:
```dart
// Từ ClubEventCard, nhấn nút "Chỉnh sửa"
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditEventScreen(event: event),
  ),
);
```

### 3. Xem danh sách người đăng ký (Event Participants)
**File**: `lib/features/event_creation/presentation/screens/event_participants_screen.dart`

**Chức năng**:
- Hiển thị thông tin sự kiện và số lượng đăng ký
- Danh sách người đăng ký với thông tin:
  - Họ tên, MSSV, Email
  - Thời gian đăng ký
  - Trạng thái (Đã đăng ký, Đã tham gia, Đã hủy)
- Filter theo trạng thái
- Pull-to-refresh để cập nhật

**API Endpoint**: `GET /api/events/{id}/participants/`

**Cách sử dụng**:
```dart
// Từ ClubEventCard, nhấn nút "Người đăng ký"
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EventParticipantsScreen(event: event),
  ),
);
```

### 4. Card sự kiện nâng cao (Enhanced ClubEventCard)
**File**: `lib/features/event_creation/presentation/widgets/club_event_card.dart`

**Cải tiến**:
- Thêm callback `onEdit` - Chỉnh sửa sự kiện
- Thêm callback `onViewParticipants` - Xem người đăng ký
- Thêm callback `onTap` - Xem chi tiết
- Layout responsive với Wrap để tránh overflow
- Các nút hành động được tổ chức logic hơn

**Sử dụng**:
```dart
ClubEventCard(
  status: 'Đã duyệt',
  statusColor: Colors.green,
  title: event.title,
  date: formatDate(event.startAt),
  location: event.location,
  organizer: event.clubName,
  image: event.posterUrl,
  onEdit: () => _navigateToEditEvent(event),
  onViewParticipants: () => _navigateToParticipants(event),
  onTap: () => _navigateToEventDetail(event),
)
```

## 📋 Cấu trúc thư mục

```
lib/features/event_creation/
├── presentation/
│   ├── screens/
│   │   ├── club_home_page.dart          # Trang chủ CLB
│   │   ├── club_events_page.dart        # Danh sách sự kiện CLB
│   │   ├── create_event_screen.dart     # [MỚI] Tạo sự kiện
│   │   ├── edit_event_screen.dart       # [MỚI] Chỉnh sửa sự kiện
│   │   └── event_participants_screen.dart # [MỚI] Danh sách người đăng ký
│   └── widgets/
│       ├── club_event_card.dart         # [CẬP NHẬT] Card sự kiện
│       ├── club_event_card_summary.dart
│       └── club_notification_tile.dart
├── data/
│   ├── api/
│   │   └── club_admin_api.dart          # API calls
│   └── repositories/
│       └── club_admin_repository.dart   # Business logic
└── domain/
    └── models/
        └── club.dart
```

## 🔄 Luồng hoạt động

### Tạo sự kiện mới
1. Club Admin vào `ClubEventsPage`
2. Nhấn nút **"Tạo sự kiện mới"**
3. Điền form trong `CreateEventScreen`
4. Submit → API `POST /api/events/`
5. Thành công → Quay về `ClubEventsPage` và reload danh sách

### Chỉnh sửa sự kiện
1. Club Admin vào `ClubEventsPage`
2. Nhấn nút **"Chỉnh sửa"** trên card sự kiện
3. `EditEventScreen` load dữ liệu hiện tại
4. Chỉnh sửa thông tin
5. Submit → API `PUT /api/events/{id}/`
6. Thành công → Quay về và reload

### Xem người đăng ký
1. Club Admin vào `ClubEventsPage`
2. Nhấn nút **"Người đăng ký"** trên card sự kiện
3. `EventParticipantsScreen` hiển thị:
   - Thông tin sự kiện (tên, số lượng đã đăng ký/capacity)
   - Filter theo trạng thái
   - Danh sách người dùng với thông tin chi tiết
4. Pull-to-refresh để cập nhật

## 🎨 UI/UX Features

### Form Validation
- ✅ Validate tất cả field bắt buộc
- ✅ Validate số dương cho capacity
- ✅ Validate thời gian kết thúc > thời gian bắt đầu
- ✅ Hiển thị error message cụ thể

### Date/Time Picker
- ✅ DatePicker với theme indigo
- ✅ TimePicker với theme indigo
- ✅ Hiển thị format: dd/MM/yyyy HH:mm
- ✅ Giới hạn date range hợp lý

### Status Display
- ✅ Badge màu sắc theo trạng thái
- ✅ Icon phù hợp với từng trạng thái
- ✅ Text mô tả rõ ràng

### Error Handling
- ✅ Loading indicators
- ✅ Error messages
- ✅ Retry buttons
- ✅ Empty state placeholders

## 🔐 Authentication

Tất cả API calls đều sử dụng `DioProvider.instance` để đảm bảo:
- ✅ Token authentication tự động
- ✅ Refresh token khi hết hạn
- ✅ 401 handling

```dart
// Tất cả API classes đã được cập nhật
EventApi({Dio? dio}) : dio = dio ?? DioProvider.instance;
ClubApi({Dio? dio}) : dio = dio ?? DioProvider.instance;
NotificationApi({Dio? dio}) : dio = dio ?? DioProvider.instance;
AdminApi({Dio? dio}) : dio = dio ?? DioProvider.instance;
ApprovalApi({Dio? dio}) : dio = dio ?? DioProvider.instance;
```

## 📝 Model Structure

### Event Model
```dart
class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final String locationDetail;
  final String category;
  final DateTime startAt;
  final DateTime? endAt;
  final int capacity;
  final int participantCount;
  final String? status;
  final String clubName;
  final String? clubId;
  final String posterUrl;
  final bool isFeatured;
  // ... more fields
}
```

### Participant Data Structure (từ API)
```json
{
  "user": {
    "id": 1,
    "full_name": "Nguyễn Văn A",
    "email": "student@example.com",
    "student_id": "12345678"
  },
  "status": "registered",
  "registered_at": "2024-01-15T10:30:00Z"
}
```

## 🚀 Cách test

### 1. Test tạo sự kiện
```bash
# Đăng nhập với tài khoản Club Admin
# Vào ClubEventsPage
# Nhấn "Tạo sự kiện mới"
# Điền form và submit
# Kiểm tra sự kiện mới xuất hiện trong danh sách
```

### 2. Test chỉnh sửa
```bash
# Từ danh sách sự kiện
# Nhấn "Chỉnh sửa" trên một sự kiện
# Thay đổi thông tin
# Submit và kiểm tra cập nhật
```

### 3. Test xem người đăng ký
```bash
# Đăng ký vài sinh viên vào sự kiện
# Nhấn "Người đăng ký"
# Kiểm tra danh sách hiển thị đúng
# Test filter theo trạng thái
```

## ⚠️ Known Issues & Future Enhancements

### Known Issues
- Chức năng upload poster chưa implement
- Export danh sách người đăng ký chưa có
- Không có xác nhận trước khi xóa sự kiện

### Future Enhancements
1. **Image Upload**: Cho phép upload poster từ device
2. **Export Participants**: Xuất danh sách ra Excel/CSV
3. **QR Code**: Generate QR code để check-in sự kiện
4. **Push Notifications**: Thông báo khi có người đăng ký
5. **Analytics**: Thống kê chi tiết về sự kiện
6. **Bulk Actions**: Thao tác hàng loạt với nhiều sự kiện

## 🔗 Related Files

### API Layer
- `lib/features/event_management/data/api/event_api.dart` - Event API
- `lib/features/event_creation/data/api/club_admin_api.dart` - Club Admin API
- `lib/core/api/dio_provider.dart` - Dio singleton with auth

### Repository Layer
- `lib/features/event_creation/data/repositories/club_admin_repository.dart`
- `lib/features/event_management/data/repositories/event_repository.dart`

### Models
- `lib/features/event_management/domain/models/event.dart`
- `lib/features/event_creation/domain/models/club.dart`

## 📞 Support

Nếu gặp vấn đề, kiểm tra:
1. API server đang chạy tại `http://192.168.1.105:8000/`
2. Token authentication đang hoạt động
3. User có role `club_admin`
4. Logs trong terminal và debug console
