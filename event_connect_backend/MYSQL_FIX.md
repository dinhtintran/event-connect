# 🚨 Khắc phục lỗi MySQL Authentication Plugin

## Vấn đề
Lỗi: `Authentication plugin 'mysql_native_password' cannot be loaded`

## Nguyên nhân
Bạn có MySQL 9.5.0 cài đặt qua Homebrew đang chạy trên port 3306, conflict với MySQL Docker container.

## ✅ Giải pháp nhanh

### Bước 1: Dừng MySQL local
```bash
# Kiểm tra process nào đang dùng port 3306
lsof -i :3306

# Dừng MySQL local
brew services stop mysql
```

### Bước 2: Reset và khởi động Docker MySQL
```bash
cd event_connect_backend

# Stop và xóa containers/volumes cũ
docker-compose down -v

# Khởi động lại
docker-compose up -d

# Chờ MySQL sẵn sàng (10-15 giây)
sleep 15
```

### Bước 3: Chạy migrations
```bash
python manage.py migrate
```

### Bước 4: Chạy server
```bash
python manage.py runserver
```

## 🤖 Hoặc dùng script tự động

```bash
chmod +x start_mysql.sh
./start_mysql.sh
```

Script này sẽ:
- Kiểm tra port 3306
- Hỏi có muốn dừng MySQL local không
- Reset Docker containers
- Chạy migrations tự động

## 🔍 Kiểm tra MySQL đang chạy

```bash
# Kiểm tra Docker containers
docker ps

# Kết nối vào MySQL container
docker exec -it event_connect_mysql mysql -u user -p
# Password: 123456
```

## 📝 Lưu ý quan trọng

### Chỉ chạy 1 MySQL instance
Bạn **KHÔNG THỂ** chạy đồng thời:
- MySQL local (Homebrew) trên port 3306
- MySQL Docker container trên port 3306

### Các option:

**Option 1: Chỉ dùng Docker (Khuyến nghị)**
```bash
brew services stop mysql  # Dừng MySQL local
docker-compose up -d       # Dùng Docker
```

**Option 2: Thay đổi port Docker**
Sửa `docker-compose.yml`:
```yaml
ports:
  - "3307:3306"  # Map port 3307 thay vì 3306
```

Và sửa `settings.py`:
```python
'PORT': '3307',  # Thay vì 3306
```

**Option 3: Dùng MySQL local (Không khuyến nghị)**
- Tạo database `event_connect_db` trong MySQL local
- Tạo user `user` với password `123456`
- Không cần Docker

## 🧪 Test kết nối

```bash
# Test từ command line
mysql -h 127.0.0.1 -P 3306 -u user -p
# Nhập password: 123456

# Kiểm tra database
SHOW DATABASES;
USE event_connect_db;
SHOW TABLES;
```

## ⚙️ Cấu hình hiện tại

**Docker Compose:**
- Image: `mysql:8.0`
- Container: `event_connect_mysql`
- Port: `3306`

**Django Settings:**
- Database: `event_connect_db`
- User: `user`
- Password: `123456`
- Host: `127.0.0.1`
- Port: `3306`

## 🆘 Nếu vẫn lỗi

1. **Xóa hoàn toàn và bắt đầu lại:**
```bash
docker-compose down -v
docker system prune -a
docker-compose up -d
sleep 15
python manage.py migrate
```

2. **Kiểm tra logs:**
```bash
docker-compose logs mysql
```

3. **Kiểm tra MySQL có chạy không:**
```bash
docker exec event_connect_mysql mysql -u user -p -e "SELECT 1;"
```

