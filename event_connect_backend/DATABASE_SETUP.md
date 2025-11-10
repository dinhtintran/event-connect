# 🔧 Hướng dẫn Setup Database

## ⚠️ Vấn đề hiện tại
Database `event_connect_db` đã có tables cũ, gây conflict khi chạy migrations.

## 🎯 Giải pháp (chọn 1 trong 2)

### Cách 1: Reset Database Hoàn Toàn (XÓA TẤT CẢ DỮ LIỆU)

**Bước 1:** Reset Docker container và database
```bash
cd event_connect_backend
docker-compose down -v
docker-compose up -d
```

**Bước 2:** Chờ MySQL khởi động (khoảng 10-15 giây)
```bash
# Kiểm tra MySQL đã sẵn sàng chưa
docker exec event_connect_mysql mysqladmin ping -h localhost
```

**Bước 3:** Chạy migrations
```bash
python manage.py migrate
```

**Bước 4:** (Tùy chọn) Tạo superuser
```bash
python manage.py createsuperuser
```

**Bước 5:** (Tùy chọn) Populate test data
```bash
python populate_data.py
```

### Cách 2: Chỉ Xóa Tables (Giữ Docker Container)

**Bước 1:** Chạy script reset_db.py
```bash
python reset_db.py
# Nhập "yes" khi được hỏi
```

**Bước 2:** Chạy migrations
```bash
python manage.py migrate
```

**Bước 3:** (Tùy chọn) Populate test data
```bash
python populate_data.py
```

## 📝 Thông tin Database

- **Database Name:** `event_connect_db`
- **User:** `user`
- **Password:** `123456`
- **Host:** `127.0.0.1` (hoặc `localhost`)
- **Port:** `3306`

## 🚀 Chạy Server

```bash
python manage.py runserver
```

Server sẽ chạy tại: `http://127.0.0.1:8000/`

## 📱 Kết nối từ Flutter App

- **Android Emulator:** Sử dụng `http://10.0.2.2:8000/`
- **iOS Simulator:** Sử dụng `http://127.0.0.1:8000/`
- **Web:** Sử dụng `http://127.0.0.1:8000/`

Base URL đã được cập nhật trong file:
`lib/core/config/app_config.dart`

## 🔍 Các lệnh hữu ích

```bash
# Kiểm tra trạng thái migrations
python manage.py showmigrations

# Kiểm tra Docker containers
docker-compose ps

# Xem logs MySQL
docker-compose logs mysql

# Truy cập MySQL shell
docker exec -it event_connect_mysql mysql -u user -p
# Password: 123456

# Dừng containers
docker-compose down

# Dừng và xóa volumes (XÓA DATA)
docker-compose down -v
```

## ✅ Checklist Setup

- [ ] Docker Desktop đang chạy
- [ ] Docker container MySQL đang chạy (`docker-compose ps`)
- [ ] Database được reset (`docker-compose down -v` hoặc `python reset_db.py`)
- [ ] Migrations đã chạy (`python manage.py migrate`)
- [ ] Server Django đang chạy (`python manage.py runserver`)
- [ ] Flutter app đã được hot restart sau khi thay đổi base URL

