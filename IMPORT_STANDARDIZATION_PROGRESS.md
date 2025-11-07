# Tiến độ Chuẩn hóa Imports

## ✅ Đã hoàn thành

### Authentication Feature
- ✅ `presentation/screens/login_screen.dart`
- ✅ `presentation/screens/register_screen.dart`

### Admin Dashboard Feature
- ✅ `presentation/screens/admin_home_screen.dart`
- ✅ `presentation/widgets/activity_item.dart`
- ✅ `presentation/widgets/pending_event_card.dart`

### Core
- ✅ `widgets/app_nav_bar.dart`

## ⏳ Cần tiếp tục

### Event Management Feature
- [ ] `presentation/screens/home_screen.dart`
- [ ] `presentation/screens/explore_screen.dart`
- [ ] `presentation/screens/my_events_screen.dart`
- [ ] `presentation/screens/event_detail_screen.dart`
- [ ] `presentation/widgets/category_chip.dart`
- [ ] `presentation/widgets/event_card_large.dart`
- [ ] `presentation/widgets/event_list_item.dart`

### Event Creation Feature
- [ ] `presentation/screens/club_home_page.dart`
- [ ] `presentation/screens/club_events_page.dart`
- [ ] `presentation/widgets/club_event_card.dart`
- [ ] `presentation/widgets/club_event_card_summary.dart`
- [ ] `presentation/widgets/club_notification_tile.dart`

### Event Approval Feature
- [ ] `presentation/screens/approval_screen.dart`
- [ ] `presentation/widgets/approval_dialog.dart`
- [ ] `presentation/widgets/approval_event_card.dart`

### Admin Dashboard Feature (còn lại)
- [ ] `presentation/widgets/stat_card.dart`
- [ ] `presentation/widgets/quick_action_button.dart`

### Core
- [ ] `navigation/main_screen.dart`

## 📝 Pattern cần áp dụng

```dart
// ❌ Relative imports
import '../../domain/models/event.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../widgets/stat_card.dart';

// ✅ Package imports
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/core/widgets/app_nav_bar.dart';
import 'package:event_connect/features/admin_dashboard/presentation/widgets/stat_card.dart';
```

