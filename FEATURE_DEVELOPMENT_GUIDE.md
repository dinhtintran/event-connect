# Feature Development Guide

> Hướng dẫn phát triển feature mới cho Event Connect App

## 📋 Mục lục

- [Kiến trúc tổng quan](#kiến-trúc-tổng-quan)
- [Tạo feature mới](#tạo-feature-mới)
- [Quy ước đặt tên](#quy-ước-đặt-tên)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Checklist tạo feature](#checklist-tạo-feature)
- [Ví dụ thực tế](#ví-dụ-thực-tế)
- [Best Practices](#best-practices)

---

## 🏗️ Kiến trúc tổng quan

Project sử dụng **Feature-Based Architecture** kết hợp **Layered Architecture**:

```
lib/
├── core/                    # Shared code (widgets, utils, config)
├── features/                # Feature modules
│   └── <feature_name>/
│       ├── data/            # Data layer (API, repositories, storage)
│       ├── domain/          # Business logic (models, services, use cases)
│       ├── presentation/    # UI (screens, widgets)
│       └── <feature>.dart   # Barrel file
└── main.dart
```

### Nguyên tắc cốt lõi:

1. **Separation of Concerns**: Mỗi layer có trách nhiệm riêng
2. **Dependency Rule**: Domain không phụ thuộc vào Data hoặc Presentation
3. **Feature Independence**: Các feature độc lập, ít coupling
4. **Package Imports**: Luôn dùng `package:event_connect/...` thay vì relative imports

---

## 🆕 Tạo feature mới

### Bước 1: Tạo cấu trúc thư mục

```bash
lib/features/<feature_name>/
├── data/
│   ├── api/                 # API clients
│   ├── repositories/        # Repository implementations
│   └── storage/             # Local storage (if needed)
├── domain/
│   ├── models/              # Domain models/entities
│   └── services/            # Business logic services
├── presentation/
│   ├── screens/             # Full-screen pages
│   └── widgets/             # Reusable UI components
└── <feature_name>.dart      # Barrel file
```

### Bước 2: Tạo barrel file

File: `lib/features/<feature_name>/<feature_name>.dart`

```dart
/// Barrel export for <feature_name> feature.
/// 
/// Import this file to access all public APIs of the <feature_name> feature.
/// 
/// Example:
/// ```dart
/// import 'package:event_connect/features/<feature_name>/<feature_name>.dart';
/// ```

library;

// Domain
export 'domain/models/model_name.dart';
export 'domain/services/service_name.dart';

// Data (nếu cần expose)
export 'data/repositories/repository_name.dart';

// Presentation
export 'presentation/screens/screen_name.dart';
export 'presentation/widgets/widget_name.dart';
```

**Lưu ý:** Dòng `library;` quan trọng để tránh analyzer warning!

### Bước 3: Tạo domain models

File: `lib/features/<feature_name>/domain/models/<model>.dart`

```dart
class ModelName {
  final int id;
  final String name;
  // ... other fields

  ModelName({
    required this.id,
    required this.name,
  });

  /// Factory constructor để parse từ JSON (API response)
  factory ModelName.fromJson(Map<String, dynamic> json) {
    return ModelName(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  /// Convert model sang JSON (để gửi API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// CopyWith cho immutable updates
  ModelName copyWith({
    int? id,
    String? name,
  }) {
    return ModelName(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
```

### Bước 4: Tạo repository (nếu cần gọi API)

File: `lib/features/<feature_name>/data/repositories/<feature>_repository.dart`

```dart
import 'package:dio/dio.dart';
import 'package:event_connect/features/<feature_name>/domain/models/<model>.dart';

class FeatureRepository {
  final Dio _dio;

  FeatureRepository({required Dio dio}) : _dio = dio;

  /// Lấy danh sách items từ API
  Future<List<ModelName>> getItems() async {
    try {
      final response = await _dio.get('/api/<endpoint>/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ModelName.fromJson(json)).toList();
      }
      throw Exception('Failed to load items');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Tạo item mới
  Future<ModelName> createItem(ModelName item) async {
    try {
      final response = await _dio.post(
        '/api/<endpoint>/',
        data: item.toJson(),
      );
      if (response.statusCode == 201) {
        return ModelName.fromJson(response.data);
      }
      throw Exception('Failed to create item');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
```

### Bước 5: Tạo service (Business logic)

File: `lib/features/<feature_name>/domain/services/<feature>_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:event_connect/features/<feature_name>/domain/models/<model>.dart';
import 'package:event_connect/features/<feature_name>/data/repositories/<feature>_repository.dart';

class FeatureService extends ChangeNotifier {
  final FeatureRepository _repository;
  
  List<ModelName> _items = [];
  bool _isLoading = false;
  String? _error;

  FeatureService({required FeatureRepository repository}) 
      : _repository = repository;

  List<ModelName> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.getItems();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(ModelName item) async {
    try {
      final newItem = await _repository.createItem(item);
      _items.add(newItem);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
```

### Bước 6: Tạo screens

File: `lib/features/<feature_name>/presentation/screens/<screen_name>.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/<feature_name>/<feature_name>.dart';

class FeatureScreen extends StatefulWidget {
  const FeatureScreen({super.key});

  @override
  State<FeatureScreen> createState() => _FeatureScreenState();
}

class _FeatureScreenState extends State<FeatureScreen> {
  @override
  void initState() {
    super.initState();
    // Load data khi screen khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeatureService>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Title'),
      ),
      body: Consumer<FeatureService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.error != null) {
            return Center(child: Text('Error: ${service.error}'));
          }

          return ListView.builder(
            itemCount: service.items.length,
            itemBuilder: (context, index) {
              final item = service.items[index];
              return ListTile(
                title: Text(item.name),
                // ... other widgets
              );
            },
          );
        },
      ),
    );
  }
}
```

### Bước 7: Đăng ký Provider trong main.dart

File: `lib/main.dart`

```dart
import 'package:event_connect/features/<feature_name>/<feature_name>.dart';

// Trong MultiProvider:
providers: [
  // ... existing providers
  ChangeNotifierProvider(
    create: (_) => FeatureService(
      repository: FeatureRepository(dio: dio),
    ),
  ),
],
```

### Bước 8: Thêm routes

File: `lib/app_routes.dart`

```dart
class AppRoutes {
  // ... existing routes
  static const String featureName = '/feature-name';
}
```

File: `lib/main.dart`

```dart
routes: {
  // ... existing routes
  AppRoutes.featureName: (_) => const FeatureScreen(),
},
```

---

## 📝 Quy ước đặt tên

### Files & Folders

- **snake_case** cho tất cả files và folders
- Tên file phản ánh nội dung: `user_profile_screen.dart`, `event_card.dart`
- Barrel file trùng tên feature: `authentication.dart` cho feature `authentication`

### Classes

- **PascalCase** cho class names
- Screen: `<Name>Screen` (ví dụ: `LoginScreen`, `ProfileScreen`)
- Widget: `<Name>Widget` hoặc `<Name>Card` (ví dụ: `EventCard`, `UserAvatar`)
- Model: `<Name>` (ví dụ: `User`, `Event`)
- Service: `<Name>Service` (ví dụ: `AuthService`, `EventService`)
- Repository: `<Name>Repository` (ví dụ: `AuthRepository`)

### Variables & Functions

- **camelCase** cho variables và functions
- Boolean: bắt đầu với `is`, `has`, `should` (ví dụ: `isLoading`, `hasError`)
- Private: bắt đầu với `_` (ví dụ: `_privateMethod`, `_items`)

---

## 📁 Cấu trúc thư mục chi tiết

### Domain Layer

```
domain/
├── models/              # Entities/Models
│   ├── user.dart
│   └── profile.dart
├── services/            # Business logic services
│   └── auth_service.dart
└── usecases/            # Use cases (optional, cho clean architecture)
    └── login_usecase.dart
```

**Trách nhiệm:**
- Định nghĩa business entities
- Business logic thuần túy (không phụ thuộc framework)
- Validation rules

### Data Layer

```
data/
├── api/                 # API clients
│   └── auth_api.dart
├── repositories/        # Repository implementations
│   └── auth_repository.dart
├── storage/             # Local storage
│   └── token_storage.dart
└── mappers/             # DTO to Domain mappers (optional)
    └── user_mapper.dart
```

**Trách nhiệm:**
- API calls
- Data persistence (local storage, cache)
- Data transformation (DTO ↔ Domain models)

### Presentation Layer

```
presentation/
├── screens/             # Full-screen pages
│   ├── login_screen.dart
│   └── register_screen.dart
├── widgets/             # Reusable UI components
│   ├── custom_button.dart
│   └── form_field.dart
└── providers/           # State management (optional nếu không dùng services)
    └── auth_provider.dart
```

**Trách nhiệm:**
- UI components
- User interactions
- State management (thông qua Provider/Service)

---

## ✅ Checklist tạo feature

Khi tạo feature mới, đảm bảo hoàn thành các bước sau:

### Setup cơ bản
- [ ] Tạo folder `lib/features/<feature_name>/`
- [ ] Tạo 3 folders con: `data/`, `domain/`, `presentation/`
- [ ] Tạo barrel file `<feature_name>.dart` với `library;` directive

### Domain Layer
- [ ] Tạo models trong `domain/models/`
- [ ] Implement `fromJson()` và `toJson()` cho mỗi model
- [ ] Tạo service trong `domain/services/` (nếu cần state management)
- [ ] Export models/services trong barrel file

### Data Layer (nếu cần API)
- [ ] Tạo API client trong `data/api/`
- [ ] Tạo repository trong `data/repositories/`
- [ ] Tạo storage nếu cần cache/persistence
- [ ] Export repository trong barrel file (nếu cần)

### Presentation Layer
- [ ] Tạo screens trong `presentation/screens/`
- [ ] Tạo reusable widgets trong `presentation/widgets/`
- [ ] Export screens/widgets trong barrel file

### Integration
- [ ] Đăng ký Provider trong `main.dart` (nếu có service)
- [ ] Thêm routes trong `app_routes.dart` và `main.dart`
- [ ] Import barrel file thay vì import từng file riêng lẻ

### Quality Assurance
- [ ] Chạy `flutter analyze` → 0 errors/warnings
- [ ] Viết ít nhất 1 widget test cho screen chính
- [ ] Chạy `flutter test` → all pass
- [ ] Test trên thiết bị thực/emulator

### Documentation
- [ ] Thêm doc comments cho public APIs
- [ ] Update README.md nếu cần
- [ ] Thêm ví dụ sử dụng trong barrel file

---

## 💡 Ví dụ thực tế

### Feature: Notifications

```
lib/features/notifications/
├── data/
│   ├── api/
│   │   └── notification_api.dart
│   └── repositories/
│       └── notification_repository.dart
├── domain/
│   ├── models/
│   │   └── notification.dart
│   └── services/
│       └── notification_service.dart
├── presentation/
│   ├── screens/
│   │   └── notifications_screen.dart
│   └── widgets/
│       ├── notification_tile.dart
│       └── notification_badge.dart
└── notifications.dart
```

#### 1. Model (`domain/models/notification.dart`)

```dart
class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
```

#### 2. Repository (`data/repositories/notification_repository.dart`)

```dart
import 'package:dio/dio.dart';
import 'package:event_connect/features/notifications/domain/models/notification.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository({required Dio dio}) : _dio = dio;

  Future<List<AppNotification>> getNotifications() async {
    final response = await _dio.get('/api/notifications/');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => AppNotification.fromJson(json)).toList();
    }
    throw Exception('Failed to load notifications');
  }

  Future<void> markAsRead(int id) async {
    await _dio.patch('/api/notifications/$id/', data: {'is_read': true});
  }
}
```

#### 3. Service (`domain/services/notification_service.dart`)

```dart
import 'package:flutter/foundation.dart';
import 'package:event_connect/features/notifications/notifications.dart';

class NotificationService extends ChangeNotifier {
  final NotificationRepository _repository;
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  NotificationService({required NotificationRepository repository})
      : _repository = repository;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _repository.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
```

#### 4. Screen (`presentation/screens/notifications_screen.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/notifications/notifications.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
      ),
      body: Consumer<NotificationService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.notifications.isEmpty) {
            return const Center(
              child: Text('Không có thông báo nào'),
            );
          }

          return ListView.builder(
            itemCount: service.notifications.length,
            itemBuilder: (context, index) {
              final notification = service.notifications[index];
              return NotificationTile(
                notification: notification,
                onTap: () {
                  service.markAsRead(notification.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

#### 5. Widget (`presentation/widgets/notification_tile.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:event_connect/features/notifications/domain/models/notification.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.notifications,
        color: notification.isRead ? Colors.grey : Colors.blue,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(notification.message),
      trailing: Text(
        _formatDate(notification.createdAt),
        style: const TextStyle(fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }
}
```

#### 6. Barrel file (`notifications.dart`)

```dart
/// Barrel export for notifications feature.
/// 
/// Import this file to access all public APIs of the notifications feature.
/// 
/// Example:
/// ```dart
/// import 'package:event_connect/features/notifications/notifications.dart';
/// ```

library;

// Domain
export 'domain/models/notification.dart';
export 'domain/services/notification_service.dart';

// Data
export 'data/repositories/notification_repository.dart';

// Presentation
export 'presentation/screens/notifications_screen.dart';
export 'presentation/widgets/notification_tile.dart';
```

#### 7. Provider registration (`main.dart`)

```dart
providers: [
  // ... existing providers
  ChangeNotifierProvider(
    create: (context) => NotificationService(
      repository: NotificationRepository(dio: dio),
    ),
  ),
],
```

---

## 🎯 Best Practices

### 1. Import Guidelines

✅ **GOOD - Package imports:**
```dart
import 'package:event_connect/features/authentication/authentication.dart';
import 'package:event_connect/core/widgets/primary_button.dart';
```

❌ **BAD - Relative imports:**
```dart
import '../../../core/widgets/primary_button.dart';
import '../../models/user.dart';
```

### 2. Barrel File Usage

✅ **GOOD - Import từ barrel:**
```dart
import 'package:event_connect/features/authentication/authentication.dart';

// Có thể dùng: User, AuthService, LoginScreen, etc.
```

❌ **BAD - Import từng file riêng:**
```dart
import 'package:event_connect/features/authentication/domain/models/user.dart';
import 'package:event_connect/features/authentication/domain/services/auth_service.dart';
import 'package:event_connect/features/authentication/presentation/screens/login_screen.dart';
```

### 3. State Management với Provider

✅ **GOOD - Consumer trong build:**
```dart
@override
Widget build(BuildContext context) {
  return Consumer<AuthService>(
    builder: (context, authService, child) {
      if (authService.isLoading) {
        return const CircularProgressIndicator();
      }
      return Text(authService.user?.name ?? 'Guest');
    },
  );
}
```

✅ **GOOD - context.read() cho actions:**
```dart
onPressed: () {
  context.read<AuthService>().login(email, password);
}
```

❌ **BAD - Provider.of trong build (không auto-rebuild):**
```dart
final authService = Provider.of<AuthService>(context, listen: false);
return Text(authService.user?.name ?? 'Guest'); // Won't update!
```

### 4. Error Handling

✅ **GOOD - Try-catch với user-friendly messages:**
```dart
Future<void> loadData() async {
  try {
    _data = await _repository.getData();
    notifyListeners();
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      _error = 'Phiên đăng nhập hết hạn';
    } else {
      _error = 'Không thể tải dữ liệu';
    }
    notifyListeners();
  } catch (e) {
    _error = 'Lỗi không xác định';
    notifyListeners();
  }
}
```

### 5. Model Immutability

✅ **GOOD - Immutable models với copyWith:**
```dart
class User {
  final int id;
  final String name;

  const User({required this.id, required this.name});

  User copyWith({int? id, String? name}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
```

❌ **BAD - Mutable models:**
```dart
class User {
  int id;
  String name;

  User({required this.id, required this.name});
  
  // ❌ Setter methods
  void setName(String newName) {
    name = newName;
  }
}
```

### 6. Async Operations

✅ **GOOD - Async/await với proper error handling:**
```dart
Future<void> submitForm() async {
  setState(() => _isLoading = true);
  
  try {
    await _service.submit(data);
    if (mounted) {
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### 7. Widget Composition

✅ **GOOD - Small, reusable widgets:**
```dart
class EventCard extends StatelessWidget {
  final Event event;
  
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildHeader(),
          _buildContent(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() { /* ... */ }
  Widget _buildContent() { /* ... */ }
  Widget _buildActions() { /* ... */ }
}
```

### 8. Dependency Injection

✅ **GOOD - Constructor injection:**
```dart
class AuthService extends ChangeNotifier {
  final AuthRepository _repository;
  
  AuthService({required AuthRepository repository})
      : _repository = repository;
}

// In main.dart:
ChangeNotifierProvider(
  create: (_) => AuthService(
    repository: AuthRepository(dio: dio),
  ),
)
```

❌ **BAD - Hard-coded dependencies:**
```dart
class AuthService extends ChangeNotifier {
  final _repository = AuthRepository(); // ❌ Tight coupling
}
```

---

## 🧪 Testing Guidelines

### Widget Test cho Screen

File: `test/features/<feature_name>/<screen_name>_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/<feature_name>/<feature_name>.dart';

void main() {
  testWidgets('FeatureScreen displays items', (WidgetTester tester) async {
    // Mock service
    final mockService = FeatureService(
      repository: MockFeatureRepository(),
    );

    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<FeatureService>.value(
          value: mockService,
          child: const FeatureScreen(),
        ),
      ),
    );

    // Verify
    expect(find.text('Feature Title'), findsOneWidget);
  });
}
```

### Unit Test cho Service

File: `test/features/<feature_name>/<service_name>_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:event_connect/features/<feature_name>/<feature_name>.dart';

void main() {
  group('FeatureService', () {
    late FeatureService service;
    late MockRepository mockRepo;

    setUp(() {
      mockRepo = MockRepository();
      service = FeatureService(repository: mockRepo);
    });

    test('loadItems should update items list', () async {
      // Arrange
      final testItems = [
        ModelName(id: 1, name: 'Test 1'),
        ModelName(id: 2, name: 'Test 2'),
      ];
      when(() => mockRepo.getItems()).thenAnswer((_) async => testItems);

      // Act
      await service.loadItems();

      // Assert
      expect(service.items.length, 2);
      expect(service.items[0].name, 'Test 1');
    });
  });
}
```

---

## 🚀 Quick Start Template

Để nhanh chóng tạo feature mới, copy template sau:

```bash
# 1. Tạo structure
mkdir -p lib/features/feature_name/{data/{api,repositories},domain/{models,services},presentation/{screens,widgets}}

# 2. Tạo barrel file
touch lib/features/feature_name/feature_name.dart

# 3. Tạo các file cơ bản
touch lib/features/feature_name/domain/models/model_name.dart
touch lib/features/feature_name/data/repositories/feature_repository.dart
touch lib/features/feature_name/domain/services/feature_service.dart
touch lib/features/feature_name/presentation/screens/feature_screen.dart
```

Sau đó implement từng file theo template ở trên.

---

## 📚 Tài liệu tham khảo

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Clean Architecture in Flutter](https://resocoder.com/category/tutorials/flutter/clean-architecture/)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Dio Documentation](https://pub.dev/packages/dio)

---

## 🆘 Troubleshooting

### Lỗi thường gặp:

**1. "Dangling library doc comment"**
```dart
// ❌ Thiếu library directive
/// Barrel export...

// ✅ Fix: Thêm library;
/// Barrel export...

library;

export '...';
```

**2. "Undefined name 'ModelName'"**
- Kiểm tra import có đúng package path không
- Kiểm tra barrel file có export model không
- Rebuild project: `flutter clean && flutter pub get`

**3. "Provider not found"**
- Kiểm tra đã register Provider trong `main.dart` chưa
- Kiểm tra Provider được khai báo ở level cao hơn widget đang dùng

**4. "Type mismatch errors"**
- Kiểm tra không có duplicate model definitions
- Chỉ nên có 1 canonical definition cho mỗi model

---

## ✨ Conclusion

Tuân thủ hướng dẫn này sẽ giúp:
- ✅ Code dễ maintain và scale
- ✅ Team collaboration hiệu quả
- ✅ Tránh duplicate code và conflicts
- ✅ Testing dễ dàng hơn
- ✅ Onboarding developer mới nhanh chóng

**Happy Coding! 🚀**
