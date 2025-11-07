# Feature-Based Architecture - EventConnect

## 📋 Tổng quan

Dự án đã được tái cấu trúc theo **Feature-Based Architecture** kết hợp với **Layer-Based Architecture** bên trong mỗi feature. Điều này giúp:

- **Isolation**: Mỗi feature độc lập, giảm xung đột khi làm việc nhóm
- **Scalability**: Dễ dàng thêm features mới
- **Maintainability**: Code rõ ràng, dễ bảo trì
- **Testability**: Dễ dàng test từng feature riêng biệt

## 📁 Cấu trúc thư mục

```
lib/
├── core/                          # Shared components
│   ├── config/                    # App configuration
│   │   └── app_config.dart
│   ├── constants/                 # Constants
│   │   └── app_roles.dart
│   ├── routes/                    # Route definitions
│   │   └── app_routes.dart
│   ├── interceptors/              # HTTP interceptors
│   │   └── token_interceptor.dart
│   └── widgets/                   # Shared widgets
│       ├── app_nav_bar.dart
│       ├── custom_text_field.dart
│       └── primary_button.dart
│
├── features/                      # Feature modules
│   ├── authentication/            # Feature: Authentication
│   │   ├── presentation/          # UI Layer
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── widgets/
│   │   ├── domain/                # Business Logic Layer
│   │   │   ├── models/
│   │   │   │   └── user.dart
│   │   │   └── services/
│   │   │       └── auth_service.dart
│   │   └── data/                  # Data Layer
│   │       ├── api/
│   │       │   └── auth_api.dart
│   │       ├── repositories/
│   │       │   └── auth_repository.dart
│   │       └── storage/
│   │           └── token_storage.dart
│   │
│   ├── event_management/          # Feature: Event Management (Student)
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── explore_screen.dart
│   │   │   │   ├── my_events_screen.dart
│   │   │   │   └── event_detail_screen.dart
│   │   │   └── widgets/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── event.dart
│   │   │   └── repositories/      # Repository interfaces
│   │   └── data/
│   │       ├── api/
│   │       ├── repositories/      # Repository implementations
│   │       └── data_sources/
│   │
│   ├── event_creation/            # Feature: Event Creation (Club)
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── club_home_page.dart
│   │   │   │   └── club_events_page.dart
│   │   │   └── widgets/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   └── data/
│   │       ├── api/
│   │       └── repositories/
│   │
│   ├── event_approval/            # Feature: Event Approval (Admin)
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── approval_screen.dart
│   │   │   └── widgets/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   └── data/
│   │       ├── api/
│   │       └── repositories/
│   │
│   └── admin_dashboard/           # Feature: Admin Dashboard
│       ├── presentation/
│       │   ├── screens/
│       │   │   └── admin_home_screen.dart
│       │   └── widgets/
│       ├── domain/
│       │   ├── models/
│       │   └── repositories/
│       └── data/
│           ├── api/
│           └── repositories/
│
└── main.dart                      # App entry point
```

## 🏗️ Kiến trúc Layer-Based trong mỗi Feature

Mỗi feature được tổ chức theo 3 layers:

### 1. Presentation Layer (`presentation/`)
- **Responsibility**: UI, user interaction
- **Contains**:
  - `screens/` hoặc `pages/`: Các màn hình chính
  - `widgets/`: Widgets đặc thù của feature

### 2. Domain Layer (`domain/`)
- **Responsibility**: Business logic, entities, use cases
- **Contains**:
  - `models/`: Domain models/entities
  - `repositories/`: Repository interfaces (abstract)
  - `services/`: Business logic services

### 3. Data Layer (`data/`)
- **Responsibility**: Data sources, API calls, local storage
- **Contains**:
  - `api/`: API clients
  - `repositories/`: Repository implementations
  - `data_sources/`: Local/remote data sources
  - `storage/`: Local storage (nếu cần)

## 📦 Features

### 1. Authentication Feature
**Actor**: Tất cả người dùng  
**Chức năng**:
- Đăng nhập
- Đăng ký
- Quản lý token
- Refresh token

### 2. Event Management Feature
**Actor**: Học sinh  
**Chức năng**:
- Xem danh sách sự kiện
- Tìm kiếm và lọc sự kiện
- Xem chi tiết sự kiện
- Quản lý sự kiện đã đăng ký (sắp tới, đã qua, đã lưu)

### 3. Event Creation Feature
**Actor**: Câu lạc bộ (CLB)  
**Chức năng**:
- Tạo sự kiện mới
- Quản lý sự kiện đã tạo
- Xem thống kê sự kiện
- Quản lý người tham gia

### 4. Event Approval Feature
**Actor**: Admin (Nhà trường)  
**Chức năng**:
- Xem danh sách sự kiện chờ phê duyệt
- Phê duyệt sự kiện
- Từ chối sự kiện
- Xem chi tiết sự kiện cần phê duyệt

### 5. Admin Dashboard Feature
**Actor**: Admin (Nhà trường)  
**Chức năng**:
- Dashboard tổng quan
- Thống kê (sự kiện, người dùng)
- Hoạt động gần đây
- Quick actions

## 🔄 Dependency Flow

```
Presentation Layer
       ↓
Domain Layer (Business Logic)
       ↓
Data Layer (API, Storage)
```

**Nguyên tắc**:
- Presentation chỉ phụ thuộc vào Domain
- Domain không phụ thuộc vào Presentation hoặc Data
- Data implement các interfaces từ Domain

## 🚀 Cách làm việc với Feature-Based Architecture

### Thêm Feature mới

1. Tạo thư mục feature trong `lib/features/`
2. Tạo cấu trúc 3 layers: `presentation/`, `domain/`, `data/`
3. Implement các layers theo thứ tự: Domain → Data → Presentation

### Làm việc nhóm

- Mỗi người làm việc trong feature của mình
- Các feature độc lập, giảm xung đột merge
- Chia sẻ code qua `core/` module

### Best Practices

1. **Isolation**: Không import trực tiếp giữa các features
2. **Shared Code**: Đặt code dùng chung vào `core/`
3. **Dependency Injection**: Sử dụng Provider/GetIt cho dependencies
4. **Repository Pattern**: Sử dụng repository pattern để tách business logic khỏi data source

## 📝 Ghi chú

- Các file trong thư mục cũ (`lib/src/`, `lib/screens/`, `lib/models/`) sẽ được di chuyển dần vào các features tương ứng
- Cấu trúc này cho phép dễ dàng scale và maintain code
- Mỗi feature có thể được test độc lập

## 🔜 Công việc tiếp theo

- [ ] Di chuyển các screens còn lại vào features tương ứng
- [ ] Di chuyển models vào domain của từng feature
- [ ] Tạo repositories và API clients cho các features
- [ ] Cập nhật imports trong toàn bộ project
- [ ] Xóa các file/thư mục cũ sau khi di chuyển xong

