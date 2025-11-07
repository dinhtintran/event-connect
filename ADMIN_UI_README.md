# Admin Home UI - EventConnect

## Tổng quan
Nhánh này chứa implementation của giao diện trang chủ admin cho ứng dụng EventConnect, được xây dựng theo thiết kế UI/UX đã được cung cấp.

## Các tính năng đã implement

### 1. Data Models
Đã tạo các models theo database schema:
- `User` - Quản lý thông tin người dùng
- `Event` - Quản lý sự kiện
- `Club` - Quản lý câu lạc bộ
- `Notification` - Thông báo
- `Approval` - Phê duyệt sự kiện
- `EventRegistration` - Đăng ký sự kiện
- `Feedback` - Phản hồi sự kiện
- `Activity` - Hoạt động gần đây

### 2. Reusable Widgets
Đã tạo các widgets tái sử dụng:
- `StatCard` - Card hiển thị thống kê
- `PendingEventCard` - Card sự kiện chờ phê duyệt
- `ActivityItem` - Item hoạt động gần đây
- `QuickActionButton` - Button hành động nhanh

### 3. Admin Home Screen
Màn hình trang chủ admin bao gồm:

#### a. Header
- Tiêu đề "EventConnect Admin"
- Nút thông báo (notification bell)

#### b. Tổng quan thống kê (Statistics Overview)
- Tổng số sự kiện: 1,250
- Tổng số người dùng: 8,765

#### c. Phê duyệt đang chờ xử lý (Pending Approvals)
- Hiển thị danh sách sự kiện chờ phê duyệt
- Có ảnh poster, tên sự kiện, thời gian
- Nút "Từ chối" và "Phê duyệt"
- Sample events:
  - Lễ hội âm nhạc mùa hè (15 tháng 7, 2024 lúc 18:00)
  - Hội nghị đổi mới công nghệ (22 tháng 8, 2024 lúc 09:00)

#### d. Hoạt động gần đây (Recent Activities)
- Sự kiện được phê duyệt
- Thanh toán mới
- Đăng ký người dùng mới
- Cảnh báo sự kiện

#### e. Hành động nhanh (Quick Actions)
Grid 2x2 với các actions:
- Quản lý người dùng
- Xem báo cáo
- Cài đặt ứng dụng
- Phê duyệt sự kiện

#### f. Bottom Navigation
- Trang Chủ (Home)
- Phê duyệt (Approval)
- Báo cáo (Reports)
- Hồ Sơ (Profile)

## Cấu trúc thư mục

```
lib/
├── models/
│   ├── activity.dart
│   ├── approval.dart
│   ├── club.dart
│   ├── event.dart
│   ├── event_registration.dart
│   ├── feedback.dart
│   ├── notification.dart
│   └── user.dart
├── screens/
│   └── admin/
│       └── admin_home_screen.dart
├── widgets/
│   └── admin/
│       ├── activity_item.dart
│       ├── pending_event_card.dart
│       ├── quick_action_button.dart
│       └── stat_card.dart
└── main.dart
```

## Cách chạy

1. Đảm bảo đã cài đặt Flutter SDK (version 3.9.2 hoặc cao hơn)
2. Clone repository và checkout nhánh này:
   ```bash
   git clone https://github.com/dinhtintran/event-connect.git
   cd event-connect
   git checkout feature/admin-home-ui
   ```

3. Cài đặt dependencies:
   ```bash
   flutter pub get
   ```

4. Chạy ứng dụng:
   ```bash
   flutter run
   ```

## TODO - Các bước tiếp theo

- [ ] Kết nối với API backend để lấy dữ liệu thực
- [ ] Implement các màn hình khác (Phê duyệt, Báo cáo, Hồ Sơ)
- [ ] Thêm state management (Provider/Bloc/Riverpod)
- [ ] Thêm authentication và authorization
- [ ] Thêm loading states và error handling
- [ ] Implement pagination cho danh sách
- [ ] Thêm search và filter functionality
- [ ] Thêm unit tests và widget tests
- [ ] Optimize performance
- [ ] Thêm animations và transitions

## Ghi chú

- UI được thiết kế theo Material Design 3
- Sử dụng color scheme với primary color: #6366F1
- Responsive layout cho các kích thước màn hình khác nhau
- Sample data được hard-coded, cần thay thế bằng API calls

## Screenshots

![Admin Home Screen](screenshots/admin_home.png)

---
**Ngày tạo**: November 3, 2025  
**Người thực hiện**: Thai Nam Hung  
**Nhánh**: feature/admin-home-ui

