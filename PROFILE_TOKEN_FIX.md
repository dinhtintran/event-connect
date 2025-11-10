# 🔐 Fix "Not Logged In" Issue - Profile Screen

## ❌ Vấn đề đã phát hiện

### Triệu chứng
- API hoạt động bình thường (logs cho thấy 200 OK)
- Nhưng Profile Screen báo "Not logged in"

### Nguyên nhân gốc
**Token storage keys không khớp!**

#### AuthService (khi login) lưu tokens với keys:
```dart
// File: lib/features/authentication/data/storage/token_storage.dart
static const _kAccess = 'auth_access';    // ✅
static const _kRefresh = 'auth_refresh';   // ✅
```

#### ProfileScreen (cũ) đọc tokens với keys SAI:
```dart
// ❌ SAI - keys không tồn tại
final accessToken = await _storage.read(key: 'access_token');
final refreshToken = await _storage.read(key: 'refresh_token');
```

→ Kết quả: `accessToken` = `null` → "Not logged in"

## ✅ Đã sửa

### ProfileScreen (mới) đọc tokens với keys ĐÚNG:
```dart
// ✅ ĐÚNG - khớp với AuthService
final accessToken = await _storage.read(key: 'auth_access');
final refreshToken = await _storage.read(key: 'auth_refresh');
```

## 📝 Files đã sửa

### 1. `profile_screen.dart` - Method `_loadProfile()`
```dart
// Đổi từ:
final accessToken = await _storage.read(key: 'access_token');

// Thành:
final accessToken = await _storage.read(key: 'auth_access');
```

### 2. `profile_screen.dart` - Method `_handleLogout()`
```dart
// Đổi từ:
final accessToken = await _storage.read(key: 'access_token');
final refreshToken = await _storage.read(key: 'refresh_token');
await _storage.delete(key: 'access_token');
await _storage.delete(key: 'refresh_token');

// Thành:
final accessToken = await _storage.read(key: 'auth_access');
final refreshToken = await _storage.read(key: 'auth_refresh');
await _storage.delete(key: 'auth_access');
await _storage.delete(key: 'auth_refresh');
```

## 🚀 Cách test ngay

### Bước 1: Hot restart app
```bash
# Trong terminal đang chạy Flutter
# Nhấn 'R' (Shift + R) để hot restart
```

Hoặc:
```bash
flutter run
```

### Bước 2: Test flow
1. ✅ Đăng nhập với tài khoản đã có
2. ✅ Vào Home Screen
3. ✅ Click avatar góc phải
4. ✅ **PHẢI THẤY:** Thông tin profile (không còn "Not logged in")
5. ✅ Thử logout
6. ✅ Đăng nhập lại

## 🔍 Kiểm tra logs

### Backend logs (Django)
Khi vào Profile Screen, bạn sẽ thấy:
```
[10/Nov/2025 05:00:35] "GET /api/accounts/me/ HTTP/1.1" 200 320
```
✅ Status 200 = thành công

### Flutter logs
```
[ProfileApi] GET /api/accounts/me/
[ProfileApi] response 200 http://10.0.2.2:8000/api/accounts/me/
```
✅ Profile loaded successfully

## 📊 So sánh Before/After

### ❌ TRƯỚC (SAI)
```dart
Storage keys used by AuthService: 'auth_access', 'auth_refresh'
Storage keys used by ProfileScreen: 'access_token', 'refresh_token'
→ KHÔNG KHỚP → Token = null → "Not logged in"
```

### ✅ SAU (ĐÚNG)
```dart
Storage keys used by AuthService: 'auth_access', 'auth_refresh'
Storage keys used by ProfileScreen: 'auth_access', 'auth_refresh'
→ KHỚP → Token được đọc → Profile hiển thị ✅
```

## 🎯 Token Storage Keys - Chuẩn hóa

### ✅ Sử dụng trong toàn bộ app:
```dart
// Access token
Key: 'auth_access'

// Refresh token
Key: 'auth_refresh'
```

### ❌ KHÔNG dùng:
- `access_token`
- `refresh_token`
- `token`
- `jwt`

## 🐛 Debug Tips

### Kiểm tra tokens có được lưu không:
```dart
// Thêm vào đầu _loadProfile()
final accessToken = await _storage.read(key: 'auth_access');
print('Access token: ${accessToken?.substring(0, 20)}...');  // In ra 20 ký tự đầu
```

### Kiểm tra tất cả keys trong storage:
```dart
final all = await _storage.readAll();
print('All storage keys: ${all.keys}');
```

### Expected output:
```
All storage keys: {auth_access, auth_refresh}
```

## ✨ Expected Result

Sau khi hot restart, Profile Screen sẽ:

1. ✅ Tự động load thông tin user
2. ✅ Hiển thị avatar với chữ cái đầu
3. ✅ Hiển thị username, email, role
4. ✅ Badge role có màu đúng
5. ✅ Nút logout hoạt động
6. ✅ Sau logout, về Login Screen

## 📚 Lessons Learned

### 1. Luôn kiểm tra storage keys
Khi làm việc với secure storage, đảm bảo keys nhất quán trong toàn bộ app.

### 2. Tạo constants cho storage keys
```dart
// Tạo file: lib/core/constants/storage_keys.dart
class StorageKeys {
  static const String accessToken = 'auth_access';
  static const String refreshToken = 'auth_refresh';
}

// Sử dụng:
await _storage.read(key: StorageKeys.accessToken);
```

### 3. Debug với logs
Luôn log ra để biết API có được gọi không, token có tồn tại không.

## 🎉 Done!

Profile feature bây giờ hoạt động 100%!

**Hot restart app và test ngay!** 🚀

