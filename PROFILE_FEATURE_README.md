# 👤 Profile Feature - Tính năng Hồ sơ

## ✨ Tính năng đã hoàn thành

### 1. **Profile Screen (Màn hình Hồ sơ)**
- ✅ Hiển thị thông tin user từ database thật qua API
- ✅ Avatar với chữ cái đầu của username
- ✅ Hiển thị role với màu sắc riêng biệt
- ✅ Các thông tin: username, email, role, trạng thái, ngày tạo
- ✅ Pull-to-refresh để tải lại dữ liệu
- ✅ Nút đăng xuất với xác nhận

### 2. **API Integration**
- ✅ `GET /api/accounts/me/` - Lấy thông tin profile
- ✅ `POST /api/accounts/logout/` - Đăng xuất và blacklist refresh token
- ✅ Tự động gửi JWT access token trong header

### 3. **Navigation**
- ✅ Thêm route `/profile` vào app
- ✅ Có thể truy cập từ avatar ở Home Screen
- ✅ Sau khi logout, tự động về Login Screen

## 📁 Files đã tạo

```
lib/features/profile/
├── data/
│   ├── api/
│   │   └── profile_api.dart          # API calls cho profile & logout
│   └── models/
│       └── user_profile.dart         # Model cho user data
└── presentation/
    └── screens/
        └── profile_screen.dart       # UI màn hình profile
```

## 🎯 Cách sử dụng

### Truy cập Profile Screen

**Cách 1: Từ Home Screen**
- Nhấn vào avatar (icon người) ở góc trên phải
- Màn hình Profile sẽ mở ra

**Cách 2: Navigation trực tiếp**
```dart
Navigator.pushNamed(context, AppRoutes.profile);
```

### Đăng xuất

1. Mở Profile Screen
2. Nhấn nút "Đăng xuất" (màu đỏ ở cuối trang)
3. Xác nhận trong dialog
4. App tự động:
   - Gọi API logout
   - Xóa tokens khỏi secure storage
   - Chuyển về Login Screen

## 🔧 API Endpoints

### Get Profile
```
GET /api/accounts/me/
Headers: Authorization: Bearer <access_token>

Response:
{
  "ok": true,
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "role": "student",
    "is_active": true,
    "first_name": "John",
    "last_name": "Doe",
    "date_joined": "2025-11-10T10:30:00Z"
  }
}
```

### Logout
```
POST /api/accounts/logout/
Headers: Authorization: Bearer <access_token>
Body: {
  "refresh": "<refresh_token>"
}

Response:
{
  "ok": true
}
```

## 🎨 UI Features

### Profile Header
- Avatar tròn với background màu theo theme
- Chữ cái đầu của username (viết hoa)
- Username hiển thị lớn
- Badge vai trò với màu:
  - 🔴 Admin: Màu đỏ
  - 🟣 Club Admin: Màu tím
  - 🔵 Student: Màu xanh dương

### Information Cards
- **Thông tin tài khoản**
  - Email
  - Username
  - Vai trò
  - Trạng thái hoạt động

- **Thông tin bổ sung**
  - Tên (nếu có)
  - Họ (nếu có)
  - Ngày tạo tài khoản

### Actions
- Pull down để refresh
- Nút logout ở AppBar và cuối trang

## 🧪 Testing

### Test Profile Screen

1. **Đăng nhập thành công**
2. **Vào Home Screen**
3. **Nhấn avatar góc phải**
4. **Kiểm tra:**
   - ✅ Hiển thị đúng username
   - ✅ Hiển thị đúng email
   - ✅ Hiển thị đúng role
   - ✅ Avatar có chữ cái đầu
   - ✅ Badge role có màu đúng

### Test Logout

1. **Từ Profile Screen, nhấn nút Đăng xuất**
2. **Kiểm tra:**
   - ✅ Hiện dialog xác nhận
   - ✅ Nhấn "Hủy" - không làm gì
   - ✅ Nhấn "Đăng xuất" - chuyển về Login
3. **Thử đăng nhập lại**
   - ✅ Có thể đăng nhập bình thường

### Test API Integration

```bash
# 1. Đăng nhập và lấy token
curl -X POST http://127.0.0.1:8000/api/accounts/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'

# 2. Test get profile
curl -X GET http://127.0.0.1:8000/api/accounts/me/ \
  -H "Authorization: Bearer <access_token>"

# 3. Test logout
curl -X POST http://127.0.0.1:8000/api/accounts/logout/ \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"refresh":"<refresh_token>"}'
```

## 📱 Screenshots Expected

### Profile Screen
```
┌─────────────────────────────┐
│ Hồ sơ              [Logout] │
├─────────────────────────────┤
│                             │
│         ┌─────┐             │
│         │  J  │  (Avatar)   │
│         └─────┘             │
│       john_doe              │
│      [Sinh viên]            │
│                             │
│ ┌─ Thông tin tài khoản ───┐ │
│ │ 📧 Email                 │ │
│ │    john@example.com      │ │
│ │ 👤 Username              │ │
│ │    john_doe              │ │
│ │ 🎯 Vai trò               │ │
│ │    Sinh viên             │ │
│ │ ✅ Trạng thái            │ │
│ │    Đang hoạt động        │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─ Thông tin bổ sung ─────┐ │
│ │ 📅 Ngày tạo             │ │
│ │    10/11/2025            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌───────────────────────┐   │
│ │   🚪 Đăng xuất        │   │
│ └───────────────────────┘   │
└─────────────────────────────┘
```

## 🔐 Security

- ✅ Access token được lưu trong FlutterSecureStorage
- ✅ Refresh token được blacklist khi logout
- ✅ Tokens được xóa hoàn toàn khi logout
- ✅ API yêu cầu authentication (Bearer token)

## 🐛 Troubleshooting

### Lỗi: "Not logged in"
**Nguyên nhân:** Không có access token trong storage
**Giải pháp:** Đăng nhập lại

### Lỗi: "Failed to load profile"
**Nguyên nhân:** API error hoặc token hết hạn
**Giải pháp:** 
1. Kiểm tra Django server đang chạy
2. Kiểm tra token còn valid không
3. Nhấn nút "Thử lại" trên màn hình

### Lỗi: Cannot connect to backend
**Nguyên nhân:** Backend không chạy hoặc URL sai
**Giải pháp:**
```bash
# Kiểm tra backend
cd event_connect_backend
python manage.py runserver

# Kiểm tra base URL trong app_config.dart
# Android emulator: http://10.0.2.2:8000/
# iOS simulator: http://127.0.0.1:8000/
```

## 📝 Next Steps (Tương lai)

- [ ] Edit profile (cập nhật tên, email)
- [ ] Upload avatar image
- [ ] Change password
- [ ] View user statistics (events joined, etc.)
- [ ] Dark mode support

## ✅ Checklist hoàn thành

- [x] Profile API được tạo
- [x] Profile model được tạo
- [x] Profile screen UI được tạo
- [x] Logout functionality
- [x] Navigation từ Home Screen
- [x] Routes được thêm vào app
- [x] Error handling
- [x] Pull to refresh
- [x] Loading states
- [x] Confirmation dialogs

🎉 **Tính năng Profile đã hoàn thành và sẵn sàng sử dụng!**

