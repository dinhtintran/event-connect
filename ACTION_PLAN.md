# Action Plan - Chuẩn hóa Cấu trúc Code (Incremental & Safe)

## ✅ Đã hoàn thành
- ✅ Xóa `lib/src/` và `lib/screens/` (không còn duplicate)
- ✅ Tất cả features dùng `presentation/widgets/` (thống nhất)
- ✅ Shared code đã ở `core/`
- ✅ Barrel exports đã tạo cho tất cả features

## 🎯 Cần thực hiện (Ưu tiên)

### Phase 1: Chuẩn hóa Imports (Ưu tiên cao)
**Mục tiêu:** Chuyển tất cả relative imports sang package imports

**Các file cần cập nhật:**
1. `features/authentication/presentation/screens/register_screen.dart`
2. `features/admin_dashboard/presentation/screens/admin_home_screen.dart`
3. `features/event_approval/presentation/screens/approval_screen.dart`
4. `features/event_creation/presentation/screens/club_home_page.dart`
5. Tất cả files trong `features/*/presentation/widgets/`
6. `core/navigation/main_screen.dart`
7. `core/widgets/app_nav_bar.dart`

**Pattern cần thay:**
```dart
// ❌ Relative imports
import '../../domain/models/activity.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../widgets/stat_card.dart';

// ✅ Package imports
import 'package:event_connect/features/admin_dashboard/domain/models/activity.dart';
import 'package:event_connect/core/widgets/app_nav_bar.dart';
import 'package:event_connect/features/admin_dashboard/presentation/widgets/stat_card.dart';
```

### Phase 2: Xử lý Duplicate Models
**Mục tiêu:** Đảm bảo chỉ có 1 canonical definition cho mỗi model

**Models cần xử lý:**
- `lib/models/notification.dart` → Quyết định:
  - Nếu dùng chung: Di chuyển vào `core/models/notification.dart`
  - Nếu thuộc feature: Di chuyển vào feature tương ứng
  - Nếu không dùng: Xóa

- `lib/models/event_registration.dart` → Di chuyển vào `features/event_management/domain/models/`
- `lib/models/feedback.dart` → Di chuyển vào `features/event_management/domain/models/`

**Kiểm tra:**
- ✅ `User` - chỉ có trong `features/authentication/domain/models/user.dart`
- ✅ `Event` - chỉ có trong `features/event_management/domain/models/event.dart`
- ✅ `Club` - chỉ có trong `features/event_creation/domain/models/club.dart`
- ✅ `Approval` - chỉ có trong `features/event_approval/domain/models/approval.dart`
- ✅ `Activity` - chỉ có trong `features/admin_dashboard/domain/models/activity.dart`

### Phase 3: Cập nhật Imports sau khi di chuyển models
Sau khi di chuyển models, cập nhật tất cả imports liên quan.

### Phase 4: Xóa lib/models/ (nếu rỗng)
Sau khi di chuyển tất cả models, xóa thư mục `lib/models/`.

## 📋 Checklist chi tiết

### Phase 1: Chuẩn hóa Imports
- [ ] Authentication feature
  - [ ] `presentation/screens/login_screen.dart`
  - [ ] `presentation/screens/register_screen.dart`
- [ ] Event Management feature
  - [ ] `presentation/screens/home_screen.dart`
  - [ ] `presentation/screens/explore_screen.dart`
  - [ ] `presentation/screens/my_events_screen.dart`
  - [ ] `presentation/screens/event_detail_screen.dart`
  - [ ] `presentation/widgets/*.dart`
- [ ] Event Creation feature
  - [ ] `presentation/screens/club_home_page.dart`
  - [ ] `presentation/screens/club_events_page.dart`
  - [ ] `presentation/widgets/*.dart`
- [ ] Event Approval feature
  - [ ] `presentation/screens/approval_screen.dart`
  - [ ] `presentation/widgets/*.dart`
- [ ] Admin Dashboard feature
  - [ ] `presentation/screens/admin_home_screen.dart`
  - [ ] `presentation/widgets/*.dart`
- [ ] Core
  - [ ] `navigation/main_screen.dart`
  - [ ] `widgets/app_nav_bar.dart`

### Phase 2: Xử lý Models
- [ ] Kiểm tra `lib/models/notification.dart` có được sử dụng không
- [ ] Di chuyển `event_registration.dart` → `features/event_management/domain/models/`
- [ ] Di chuyển `feedback.dart` → `features/event_management/domain/models/`
- [ ] Xử lý `notification.dart` (di chuyển hoặc xóa)
- [ ] Cập nhật imports sau khi di chuyển
- [ ] Xóa `lib/models/` nếu rỗng

### Phase 3: Verification
- [ ] Chạy `flutter analyze` - không có lỗi
- [ ] Chạy `flutter test` - tất cả tests pass
- [ ] Test app manually - không có lỗi runtime
- [ ] Kiểm tra không còn relative imports
- [ ] Kiểm tra không còn duplicate models

## 🚀 Bắt đầu thực hiện

Tôi sẽ bắt đầu với Phase 1 (chuẩn hóa imports) vì đây là ưu tiên cao nhất.

