# 📋 Tóm tắt các thay đổi đã thực hiện

## 🔧 Backend Configuration Changes

### 1. Database Settings (`event_connect_backend/settings.py`)
**Thay đổi:**
- Database name: `event_connect` → `event_connect_db`
- User: `root` → `user`
- Password: `Tvds@2312003` → `123456`
- Host: `localhost` → `127.0.0.1` (để tránh lỗi MySQL socket)
- Thêm charset: `utf8mb4`
- ALLOWED_HOSTS: `[]` → `['127.0.0.1', 'localhost']`

**Lý do:**
- Đồng bộ với cấu hình Docker Compose
- Sử dụng TCP/IP connection thay vì Unix socket
- Cho phép Django accept connections từ localhost

### 2. Docker Compose (`docker-compose.yml`)
**Thay đổi:**
- Xóa field `version: '3.8'` (deprecated)
- Thêm `command: --default-authentication-plugin=mysql_native_password`

**Lý do:**
- Tránh warning từ Docker Compose mới
- Tương thích tốt hơn với DBeaver và các MySQL clients

## 📱 Flutter App Changes

### 1. API Base URL (`lib/core/config/app_config.dart`)
**Thay đổi:**
- URL: `http://127.0.0.1:8000/` → `http://10.0.2.2:8000/`

**Lý do:**
- Android emulator không thể kết nối đến `127.0.0.1` của máy host
- `10.0.2.2` là địa chỉ đặc biệt của Android emulator trỏ đến host machine's localhost

## 🆕 New Files Created

1. **`DATABASE_SETUP.md`** - Hướng dẫn chi tiết setup database
2. **`quick_setup.py`** - Script tự động reset và setup database
3. **`reset_and_migrate.sh`** - Bash script cho Linux/Mac users

## 🚀 Cách sử dụng

### Option 1: Tự động (khuyến nghị)
```bash
cd event_connect_backend
python quick_setup.py
# Nhập "yes" để confirm
```

### Option 2: Thủ công
```bash
# Reset Docker và database
docker-compose down -v
docker-compose up -d

# Chờ 10-15 giây cho MySQL khởi động

# Run migrations
python manage.py migrate

# Run server
python manage.py runserver
```

### Option 3: Chỉ reset tables (giữ Docker container)
```bash
python reset_db.py
# Nhập "yes" để confirm

python manage.py migrate
```

## ✅ Checklist để chạy được app

- [x] Cấu hình database đã được cập nhật
- [x] Docker Compose đã được tối ưu
- [x] Flutter app base URL đã được thay đổi
- [ ] Chạy `quick_setup.py` hoặc reset database thủ công
- [ ] Chạy `python manage.py runserver`
- [ ] Hot restart Flutter app để load base URL mới

## 🔍 Troubleshooting

### Lỗi: "Authentication plugin 'mysql_native_password' cannot be loaded"
**Nguyên nhân:** MySQL local (Homebrew) đang chạy trên port 3306, conflict với Docker container

**Giải pháp:**
```bash
# Dừng MySQL local
brew services stop mysql

# Reset Docker
docker-compose down -v
docker-compose up -d

# Chờ 15 giây
sleep 15

# Chạy migrations
python manage.py migrate
```

Xem chi tiết: `MYSQL_FIX.md`

### Lỗi: "Table already exists"
**Giải pháp:** Chạy `python quick_setup.py` hoặc `python reset_db.py`

### Lỗi: "Connection refused" từ Flutter app
**Kiểm tra:**
1. Django server có đang chạy không? (`python manage.py runserver`)
2. Base URL trong Flutter app đã là `10.0.2.2` chưa?
3. ALLOWED_HOSTS trong Django settings đã có `127.0.0.1` chưa?

### Lỗi: "Can't connect to MySQL socket"
**Giải pháp:** 
1. Kiểm tra Docker container: `docker-compose ps`
2. Đảm bảo HOST trong settings.py là `127.0.0.1` (không phải `localhost`)
3. Kiểm tra port 3306 có bị chiếm không: `lsof -i :3306`

### DBeaver không connect được
**Giải pháp:**
1. Thêm driver property: `allowPublicKeyRetrieval=true`
2. Sử dụng `caching_sha2_password` authentication method

## 📞 Thông tin kết nối

**MySQL Database:**
- Host: `127.0.0.1`
- Port: `3306`
- Database: `event_connect_db`
- User: `user`
- Password: `123456`

**Django Server:**
- Development: `http://127.0.0.1:8000/`
- From Android Emulator: `http://10.0.2.2:8000/`

**Admin Panel:**
- URL: `http://127.0.0.1:8000/admin/`
- Tạo superuser: `python manage.py createsuperuser`

