# ✅ CHECKLIST - Đã fix xong lỗi ALLOWED_HOSTS

## 🔧 Thay đổi vừa thực hiện

### File: `event_connect_backend/settings.py`
```python
# TRƯỚC:
ALLOWED_HOSTS = ['127.0.0.1', 'localhost']

# SAU:
ALLOWED_HOSTS = ['127.0.0.1', 'localhost', '10.0.2.2']
```

**Lý do:** Android emulator gửi request với HTTP_HOST header là `10.0.2.2:8000`, Django cần có domain này trong ALLOWED_HOSTS.

---

## 🚀 Làm NGAY BÂY GIỜ

### 1. RESTART Django server

**Trong terminal đang chạy server:**
- Nhấn `Ctrl + C` để dừng server
- Chạy lại: `python manage.py runserver`

**Hoặc nếu chưa chạy server:**
```bash
cd /Users/tin/Desktop/Project\ University/event-connect/event_connect_backend
python manage.py runserver
```

### 2. Test lại trên Flutter app

1. **Hot restart** Flutter app (nhấn `R` trong terminal hoặc restart button)
2. Thử **đăng nhập** hoặc **đăng ký** lại
3. Kiểm tra logs của Django server

---

## 📋 Cấu hình hoàn chỉnh hiện tại

### Backend (Django)
- **ALLOWED_HOSTS:** `['127.0.0.1', 'localhost', '10.0.2.2']`
- **Database:** `event_connect_db`
- **MySQL User:** `user` / Password: `123456`
- **MySQL Host:** `127.0.0.1:3306` (Docker)

### Flutter App
- **Base URL:** `http://10.0.2.2:8000/`
- **File:** `lib/core/config/app_config.dart`

### Docker MySQL
- **Container:** `event_connect_mysql`
- **Port:** `3306`
- **Status:** Phải đang chạy (`docker ps`)

---

## 🎯 Expected Result

Sau khi restart server, bạn sẽ thấy:

**Khi đăng ký/đăng nhập thành công:**
```
[10/Nov/2025 04:45:00] "POST /api/accounts/register/ HTTP/1.1" 201 150
[10/Nov/2025 04:45:05] "POST /api/accounts/token/ HTTP/1.1" 200 350
```

**KHÔNG còn thấy:**
```
Invalid HTTP_HOST header: '10.0.2.2:8000'
```

---

## ✅ Checklist cuối cùng

- [x] ALLOWED_HOSTS đã có `10.0.2.2`
- [ ] Django server đã RESTART
- [ ] Flutter app đã hot restart
- [ ] Test đăng nhập/đăng ký
- [ ] Kiểm tra logs không còn lỗi HTTP_HOST

---

## 🔍 Nếu vẫn lỗi

### Lỗi khác về CORS
Kiểm tra `CORS_ALLOWED_ORIGINS` trong `settings.py`:
```python
CORS_ALLOWED_ORIGINS = [
    'http://localhost:51009',
    'http://127.0.0.1:51009',
]
```

Có thể cần thêm:
```python
CORS_ALLOW_ALL_ORIGINS = True  # Đã có trong settings
```

### Lỗi 404 Not Found
Kiểm tra URL trong Flutter app có đúng không:
- Endpoint đăng ký: `/api/accounts/register/`
- Endpoint đăng nhập: `/api/accounts/token/`

### Lỗi kết nối
```bash
# Kiểm tra server có chạy không
curl http://127.0.0.1:8000/admin/
# Hoặc
curl http://10.0.2.2:8000/admin/
```

---

## 🎉 Khi thành công

Bạn sẽ thấy:
1. ✅ Flutter app có thể đăng ký tài khoản mới
2. ✅ Flutter app có thể đăng nhập
3. ✅ Django logs hiển thị HTTP 200/201 (thành công)
4. ✅ Dữ liệu được lưu vào MySQL

Chúc mừng! Backend đã hoạt động! 🚀

