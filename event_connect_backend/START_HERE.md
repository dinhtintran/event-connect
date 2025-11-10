# ⚡ HƯỚNG DẪN NHANH - Chạy Backend Event Connect

## 🚨 Vấn đề bạn đang gặp
Bạn có MySQL local (Homebrew 9.5.0) đang chạy trên port 3306, conflict với Docker MySQL.

## ✅ Giải pháp - Làm theo CHÍNH XÁC các bước sau:

### Bước 1: Dừng MySQL local
```bash
brew services stop mysql
```

Xác nhận MySQL đã dừng:
```bash
lsof -i :3306
# Không có output = OK
```

### Bước 2: Reset Docker MySQL
```bash
cd /Users/tin/Desktop/Project\ University/event-connect/event_connect_backend

docker-compose down -v
docker-compose up -d
```

### Bước 3: Chờ MySQL khởi động
```bash
# Chờ 15 giây
sleep 15

# Hoặc kiểm tra thủ công
docker exec event_connect_mysql mysqladmin ping -h localhost
# Output: mysqld is alive = OK
```

### Bước 4: Chạy migrations
```bash
python manage.py migrate
```

**Nếu thành công**, bạn sẽ thấy:
```
Operations to perform:
  Apply all migrations: ...
Running migrations:
  Applying accounts.0001_initial... OK
  Applying clubs.0001_initial... OK
  ...
```

### Bước 5: Chạy server
```bash
python manage.py runserver
```

Server sẽ chạy tại: `http://127.0.0.1:8000/`

**⚠️ QUAN TRỌNG:** Nếu server đang chạy, bạn cần **RESTART** server sau khi thay đổi settings!

---

## 🎯 Hoặc dùng script tự động

```bash
cd /Users/tin/Desktop/Project\ University/event-connect/event_connect_backend

# Cấp quyền execute
chmod +x start_mysql.sh

# Chạy script
./start_mysql.sh
```

Script sẽ tự động làm tất cả các bước trên.

---

## 📱 Sau khi backend chạy

1. **Hot restart** Flutter app
2. Thử đăng ký tài khoản mới
3. Kiểm tra logs của Django server

---

## 🔍 Kiểm tra xem mọi thứ có OK không

```bash
# 1. Kiểm tra Docker container
docker ps
# Phải thấy: event_connect_mysql   Up

# 2. Test kết nối MySQL
docker exec -it event_connect_mysql mysql -u user -p
# Password: 123456
# Gõ: SHOW DATABASES;
# Phải thấy: event_connect_db

# 3. Test Django server
curl http://127.0.0.1:8000/api/accounts/test-connection/
```

---

## ⚠️ LƯU Ý QUAN TRỌNG

### Từ giờ, khi làm việc với project này:

**LUÔN dùng MySQL Docker**, KHÔNG dùng MySQL local:

```bash
# Khởi động Docker MySQL
docker-compose up -d

# Làm việc với Django
python manage.py runserver

# Khi xong việc
docker-compose down
```

### Nếu cần dùng MySQL local cho project khác:

**Option 1:** Dừng Docker trước
```bash
docker-compose down
brew services start mysql
```

**Option 2:** Đổi port Docker (khuyến nghị)
Sửa `docker-compose.yml`:
```yaml
ports:
  - "3307:3306"  # Dùng port 3307
```

---

## 🆘 Nếu vẫn lỗi, chạy lệnh này:

```bash
# Stop mọi thứ
brew services stop mysql
docker-compose down -v
docker stop $(docker ps -aq) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null

# Khởi động lại
docker-compose up -d
sleep 20
python manage.py migrate
python manage.py runserver
```

---

## 📚 Tài liệu bổ sung

- `MYSQL_FIX.md` - Chi tiết về lỗi MySQL authentication
- `DATABASE_SETUP.md` - Hướng dẫn setup database
- `CONFIGURATION_SUMMARY.md` - Tóm tắt tất cả thay đổi

