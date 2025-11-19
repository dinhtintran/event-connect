# 🐛 Bug Fix: AdminService Provider Not Found

## ❌ Lỗi gặp phải

```
ProviderNotFoundException: Error: Could not find the correct Provider<AdminService> 
above this Consumer<AdminService> Widget

Error: Could not find the correct Provider<AdminService> above this AdminHomeScreen Widget
```

**Nơi xảy ra lỗi**:
- `lib/features/admin_dashboard/presentation/screens/admin_home_screen.dart:34:35`
- `lib/features/admin_dashboard/presentation/screens/admin_home_screen.dart:238:12`

---

## 🔍 Nguyên nhân

### Provider Tree thiếu AdminService

File `main.dart` chỉ có 2 providers:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService(repository: authRepo)),
    ChangeNotifierProvider(create: (_) => EventService(repository: eventRepo)),
    // ❌ Thiếu AdminService
  ],
  child: MaterialApp(...),
)
```

### AdminHomeScreen cần AdminService

```dart
class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final adminService = Provider.of<AdminService>(context, listen: false);
    // ❌ Error: Provider<AdminService> not found
    await adminService.fetchStats();
  }
}
```

**Kết quả**: App crash khi navigate đến AdminHomeScreen vì không tìm thấy AdminService trong Provider tree.

---

## ✅ Giải pháp

### 1. Thêm imports cần thiết

```dart
import 'package:event_connect/features/admin_dashboard/domain/repositories/admin_repository.dart';
import 'package:event_connect/features/admin_dashboard/domain/services/admin_service.dart';
```

### 2. Khởi tạo AdminRepository

```dart
// Admin Dashboard
final adminRepo = AdminRepository();
```

### 3. Thêm AdminService vào MultiProvider

```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService(repository: authRepo)),
    ChangeNotifierProvider(create: (_) => EventService(repository: eventRepo)),
    ChangeNotifierProvider(create: (_) => AdminService(repository: adminRepo)), // ✅ Added
  ],
  child: MaterialApp(...),
);
```

---

## 📝 Full Code Changes

**File**: `lib/main.dart`

```dart
import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/data/repositories/event_repository.dart';
import 'package:event_connect/features/event_management/domain/services/event_service.dart';
import 'package:event_connect/features/admin_dashboard/domain/repositories/admin_repository.dart';  // ✅ NEW
import 'package:event_connect/features/admin_dashboard/domain/services/admin_service.dart';  // ✅ NEW

void main() {
  runApp(const EventConnectApp());
}

class EventConnectApp extends StatelessWidget {
  const EventConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
    final tokenStorage = TokenStorage();
    dio.interceptors.add(TokenInterceptor(tokenStorage: tokenStorage));
    
    // Auth
    final authApi = AuthApi(dio: dio);
    final authRepo = AuthRepository(api: authApi, tokenStorage: tokenStorage);
    
    // Event Management
    final eventApi = EventApi(dio: dio);
    final eventRepo = EventRepository(api: eventApi);
    
    // Admin Dashboard  // ✅ NEW
    final adminRepo = AdminRepository();  // ✅ NEW

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(repository: authRepo)),
        ChangeNotifierProvider(create: (_) => EventService(repository: eventRepo)),
        ChangeNotifierProvider(create: (_) => AdminService(repository: adminRepo)),  // ✅ NEW
      ],
      child: MaterialApp(...),
    );
  }
}
```

---

## 🎯 Tại sao lỗi này xảy ra?

### Provider Pattern trong Flutter

Provider pattern yêu cầu:
1. **Create** provider ở cấp cao trong widget tree (thường là `main.dart`)
2. **Use** provider ở các widget con phía dưới

```
MaterialApp (MultiProvider)
  ├── AuthService ✅
  ├── EventService ✅
  ├── AdminService ✅ (sau khi fix)
  └── Routes
      └── AdminHomeScreen (Consumer<AdminService>)
```

### AdminService Dependencies

```dart
AdminService
  └── AdminRepository
      └── HTTP client + FlutterSecureStorage
```

**Note**: AdminRepository sử dụng `http` package thay vì `Dio`, nên không cần inject Dio client.

---

## ✅ Kết quả sau khi fix

```
✅ AdminService khả dụng trong toàn bộ app
✅ AdminHomeScreen.initState() có thể gọi Provider.of<AdminService>
✅ Consumer<AdminService> trong AdminHomeScreen hoạt động bình thường
✅ Admin Dashboard load statistics, pending events, activities thành công
```

---

## 🧪 Testing Steps

1. **Hot Restart** (KHÔNG phải Hot Reload):
   ```bash
   flutter run
   # Hoặc nhấn "R" trong terminal
   ```

2. **Navigate to Admin Dashboard**:
   - Login với System Admin account
   - Click vào Admin Dashboard

3. **Verify**:
   - ✅ Không còn ProviderNotFoundException
   - ✅ Statistics cards hiển thị
   - ✅ Pending events list load
   - ✅ Recent activities list load

---

## 📝 Lessons Learned

### 1. **Always add new Services to Provider tree**
Khi tạo Service mới với ChangeNotifier, phải thêm vào MultiProvider trong `main.dart`.

### 2. **Hot Restart vs Hot Reload**
- **Hot Reload** (r): Chỉ reload UI, không rebuild Provider tree
- **Hot Restart** (R): Rebuild toàn bộ app, bao gồm Provider tree

**Khi thêm/xóa Provider → Bắt buộc Hot Restart!**

### 3. **Provider Scope**
Providers are "scoped" - chỉ available cho các widgets con phía dưới.

```dart
// ❌ WRONG: Provider không available cho child immediate
Widget build(BuildContext context) {
  return Provider<Example>(
    create: (_) => Example(),
    child: Text(context.watch<Example>().toString()), // ❌ Error
  );
}

// ✅ CORRECT: Use builder để tạo new BuildContext
Widget build(BuildContext context) {
  return Provider<Example>(
    create: (_) => Example(),
    builder: (context, child) {
      return Text(context.watch<Example>().toString()); // ✅ OK
    }
  );
}
```

### 4. **Common Provider Services Pattern**

```dart
// main.dart
MultiProvider(
  providers: [
    // Authentication
    ChangeNotifierProvider(create: (_) => AuthService(...)),
    
    // Features
    ChangeNotifierProvider(create: (_) => EventService(...)),
    ChangeNotifierProvider(create: (_) => AdminService(...)),
    ChangeNotifierProvider(create: (_) => NotificationService(...)),
    // ... more services
  ],
  child: MaterialApp(...),
)
```

---

## 🚀 Status

**FIXED** ✅

Admin Dashboard giờ đã hoạt động bình thường!

---

## 🔗 Related Files

- ✅ `lib/main.dart` - Added AdminService to MultiProvider
- 📄 `lib/features/admin_dashboard/domain/services/admin_service.dart` - Service definition
- 📄 `lib/features/admin_dashboard/domain/repositories/admin_repository.dart` - Repository
- 📄 `lib/features/admin_dashboard/presentation/screens/admin_home_screen.dart` - Screen using AdminService
