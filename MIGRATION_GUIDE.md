# Migration Guide - Tái cấu trúc Feature-Based Architecture

## ✅ Đã hoàn thành

### Core Module
- ✅ `core/config/app_config.dart` - App configuration
- ✅ `core/constants/app_roles.dart` - Role constants
- ✅ `core/routes/app_routes.dart` - Route definitions
- ✅ `core/interceptors/token_interceptor.dart` - Token interceptor
- ✅ `core/widgets/app_nav_bar.dart` - Navigation bar
- ✅ `core/widgets/custom_text_field.dart` - Text field widget
- ✅ `core/widgets/primary_button.dart` - Primary button widget

### Authentication Feature
- ✅ `features/authentication/domain/models/user.dart` - User model
- ✅ `features/authentication/domain/services/auth_service.dart` - Auth service
- ✅ `features/authentication/data/api/auth_api.dart` - Auth API
- ✅ `features/authentication/data/repositories/auth_repository.dart` - Auth repository
- ✅ `features/authentication/data/storage/token_storage.dart` - Token storage
- ✅ `features/authentication/presentation/screens/login_screen.dart` - Login screen
- ✅ `features/authentication/presentation/screens/register_screen.dart` - Register screen

### Main App
- ✅ `main.dart` - Updated to use new structure

## 🔄 Cần cập nhật

### 1. Update Imports trong các file cũ

#### Các file cần cập nhật imports:

**Old imports → New imports:**

```dart
// Auth Service
import '../src/auth/auth_service.dart';
→
import '../../features/authentication/domain/services/auth_service.dart';

// Routes
import '../src/routes.dart';
→
import '../../core/routes/app_routes.dart';

// AppNavBar
import '../widgets/app_nav_bar.dart';
→
import '../../core/widgets/app_nav_bar.dart';

// Roles
import '../src/constants/roles.dart';
→
import '../../core/constants/app_roles.dart';
```

### 2. Di chuyển các Features còn lại

#### Event Management Feature (Student)
Cần di chuyển:
- `lib/screens/home_screen.dart` → `lib/features/event_management/presentation/screens/home_screen.dart`
- `lib/screens/explore_screen.dart` → `lib/features/event_management/presentation/screens/explore_screen.dart`
- `lib/screens/my_events_screen.dart` → `lib/features/event_management/presentation/screens/my_events_screen.dart`
- `lib/screens/event_detail_screen.dart` → `lib/features/event_management/presentation/screens/event_detail_screen.dart`
- `lib/models/event.dart` → `lib/features/event_management/domain/models/event.dart`
- `lib/widgets/event_card_large.dart` → `lib/features/event_management/presentation/widgets/event_card_large.dart`
- `lib/widgets/event_list_item.dart` → `lib/features/event_management/presentation/widgets/event_list_item.dart`
- `lib/widgets/category_chip.dart` → `lib/features/event_management/presentation/widgets/category_chip.dart`

#### Event Creation Feature (Club)
Cần di chuyển:
- `lib/pages/club_home_page.dart` → `lib/features/event_creation/presentation/pages/club_home_page.dart`
- `lib/pages/club_events_page.dart` → `lib/features/event_creation/presentation/pages/club_events_page.dart`
- `lib/models/club.dart` → `lib/features/event_creation/domain/models/club.dart`

#### Event Approval Feature (Admin)
Cần di chuyển:
- `lib/screens/approval/approval_screen.dart` → `lib/features/event_approval/presentation/screens/approval_screen.dart`
- `lib/widgets/approval/approval_event_card.dart` → `lib/features/event_approval/presentation/widgets/approval_event_card.dart`
- `lib/dialogs/approval_dialog.dart` → `lib/features/event_approval/presentation/widgets/approval_dialog.dart`
- `lib/models/approval.dart` → `lib/features/event_approval/domain/models/approval.dart`

#### Admin Dashboard Feature
Cần di chuyển:
- `lib/screens/admin/admin_home_screen.dart` → `lib/features/admin_dashboard/presentation/screens/admin_home_screen.dart`
- `lib/widgets/admin/stat_card.dart` → `lib/features/admin_dashboard/presentation/widgets/stat_card.dart`
- `lib/widgets/admin/pending_event_card.dart` → `lib/features/admin_dashboard/presentation/widgets/pending_event_card.dart`
- `lib/widgets/admin/activity_item.dart` → `lib/features/admin_dashboard/presentation/widgets/activity_item.dart`
- `lib/widgets/admin/quick_action_button.dart` → `lib/features/admin_dashboard/presentation/widgets/quick_action_button.dart`
- `lib/models/activity.dart` → `lib/features/admin_dashboard/domain/models/activity.dart`

### 3. Di chuyển Shared Models

Các models có thể được dùng chung giữa các features:
- `lib/models/event_registration.dart` - Có thể được dùng bởi cả event_management và event_creation
- `lib/models/notification.dart` - Có thể được dùng bởi nhiều features
- `lib/models/feedback.dart` - Có thể được dùng bởi event_management

**Quyết định:**
- Nếu model chỉ được dùng bởi 1 feature → Di chuyển vào domain của feature đó
- Nếu model được dùng bởi nhiều features → Giữ trong `core/models/` hoặc tạo shared models module

### 4. Cập nhật Main Screen

- `lib/screens/main_screen.dart` - Cần cập nhật imports và có thể di chuyển vào core hoặc tạo navigation feature

### 5. Shared Utilities

- `lib/utils/dummy_data.dart` - Có thể di chuyển vào `core/utils/` hoặc tạo data mocks riêng cho từng feature

## 📝 Checklist Migration

### Phase 1: Core & Authentication ✅
- [x] Tạo core module
- [x] Di chuyển authentication feature
- [x] Cập nhật main.dart
- [x] Test authentication flow

### Phase 2: Event Management (In Progress)
- [ ] Di chuyển event management screens
- [ ] Di chuyển event models
- [ ] Di chuyển event widgets
- [ ] Cập nhật imports
- [ ] Test event management flow

### Phase 3: Event Creation
- [ ] Di chuyển club pages
- [ ] Di chuyển club models
- [ ] Cập nhật imports
- [ ] Test club flow

### Phase 4: Event Approval
- [ ] Di chuyển approval screen
- [ ] Di chuyển approval widgets
- [ ] Di chuyển approval models
- [ ] Cập nhật imports
- [ ] Test approval flow

### Phase 5: Admin Dashboard
- [ ] Di chuyển admin screen
- [ ] Di chuyển admin widgets
- [ ] Di chuyển admin models
- [ ] Cập nhật imports
- [ ] Test admin flow

### Phase 6: Cleanup
- [ ] Xóa các file/thư mục cũ
- [ ] Cập nhật tất cả imports
- [ ] Run tests
- [ ] Update documentation

## 🚀 Cách thực hiện migration

### Bước 1: Di chuyển file
```bash
# Example: Di chuyển event model
mv lib/models/event.dart lib/features/event_management/domain/models/event.dart
```

### Bước 2: Cập nhật imports trong file đó
```dart
// Old
import '../../models/event.dart';

// New (nếu import từ feature khác)
import '../../../event_management/domain/models/event.dart';

// Hoặc nếu import trong cùng feature
import '../../domain/models/event.dart';
```

### Bước 3: Tìm và cập nhật tất cả imports
```bash
# Tìm tất cả file import model cũ
grep -r "models/event.dart" lib/
```

### Bước 4: Test
- Chạy app và test các tính năng
- Fix các lỗi import
- Verify không có broken references

## ⚠️ Lưu ý

1. **Không xóa file cũ ngay**: Giữ lại file cũ cho đến khi tất cả imports đã được cập nhật
2. **Test từng bước**: Test sau mỗi feature migration
3. **Commit thường xuyên**: Commit sau mỗi feature hoàn thành
4. **Review code**: Review imports và dependencies

## 📚 Tài liệu tham khảo

- Xem `ARCHITECTURE.md` để hiểu rõ về cấu trúc mới
- Xem các file trong `features/authentication/` như ví dụ mẫu

