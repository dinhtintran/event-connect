# Admin Services Architecture 🏗️

## Overview
The application uses **TWO different AdminService implementations** to separate concerns:

## 1. Admin Dashboard Service (Old)
**Path**: `lib/features/admin_dashboard/domain/services/admin_service.dart`

**Purpose**: Dashboard statistics and activities

**Used By**:
- `AdminHomeScreen` - Main admin dashboard

**Methods**:
- `fetchStats()` - Get dashboard statistics
- `fetchPendingEvents()` - Get events waiting approval
- `fetchRecentActivities()` - Get recent admin activities

**Provider Registration**:
```dart
ChangeNotifierProvider<admin_dash.AdminService>(
  create: (_) => admin_dash.AdminService(),
)
```

---

## 2. Admin Management Service (New)
**Path**: `lib/features/admin/domain/services/admin_service.dart`

**Purpose**: User and Event CRUD operations

**Used By**:
- `AdminUserManagementScreen` - User management
- `AdminEventManagementScreen` - Event management

**Methods**:
- `loadUsers()` - Load all users with filters
- `activateUser()` - Activate user account
- `deactivateUser()` - Deactivate user account
- `deleteUser()` - Delete user
- `loadEvents()` - Load events with filters
- `approveEvent()` - Approve event
- `rejectEvent()` - Reject event
- `deleteEvent()` - Delete event

**Provider Registration**:
```dart
ChangeNotifierProvider<admin_mgmt.AdminService>(
  create: (_) => admin_mgmt.AdminService(repository: adminMgmtRepo),
)
```

---

## Why Two Services?

### Separation of Concerns
- **Dashboard Service**: Read-only statistics, lightweight
- **Management Service**: Full CRUD operations, heavier

### Different Data Sources
- **Dashboard Service**: Uses legacy admin_dashboard repository
- **Management Service**: Uses new admin API endpoints

### Independent Evolution
- Dashboard can be updated without affecting management
- Management features can be enhanced independently

---

## Import Strategy in main.dart

```dart
// Admin User/Event Management (new implementation)
import 'package:event_connect/features/admin/domain/services/admin_service.dart' as admin_mgmt;

// Admin Dashboard (old implementation for stats/activities)
import 'package:event_connect/features/admin_dashboard/domain/services/admin_service.dart' as admin_dash;
```

**Aliases**:
- `admin_mgmt.AdminService` - Management service
- `admin_dash.AdminService` - Dashboard service

---

## Screen Usage

### AdminHomeScreen
```dart
import 'package:event_connect/features/admin_dashboard/domain/services/admin_service.dart';

// Uses dashboard service automatically
final adminService = Provider.of<AdminService>(context, listen: false);
await adminService.fetchStats();
```

### AdminUserManagementScreen
```dart
import 'package:event_connect/features/admin/domain/services/admin_service.dart';

// Uses management service automatically
Consumer<AdminService>(
  builder: (context, adminService, _) {
    return ListView(children: adminService.users.map(...));
  },
)
```

### AdminEventManagementScreen
```dart
import 'package:event_connect/features/admin/domain/services/admin_service.dart';

// Uses management service automatically
final admin = context.read<AdminService>();
await admin.approveEvent(event.id);
```

---

## Provider Resolution

Flutter Provider resolves the correct service based on the **import** in each screen:

1. **AdminHomeScreen** imports from `admin_dashboard/` → Gets dashboard service
2. **AdminUserManagementScreen** imports from `admin/` → Gets management service
3. **AdminEventManagementScreen** imports from `admin/` → Gets management service

---

## Testing

When testing, ensure both providers are registered:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<admin_mgmt.AdminService>(
      create: (_) => MockAdminManagementService(),
    ),
    ChangeNotifierProvider<admin_dash.AdminService>(
      create: (_) => MockAdminDashboardService(),
    ),
  ],
  child: YourTestWidget(),
)
```

---

## Troubleshooting

### Error: "Could not find the correct Provider<AdminService>"

**Cause**: Screen is trying to use AdminService but the wrong one is imported

**Solution**: 
1. Check the import statement in the screen
2. Verify it matches the provider registration in main.dart
3. Perform hot-restart (hot-reload won't work for provider changes)

### Error: "Type 'admin_dash.AdminService' is not a subtype of type 'admin_mgmt.AdminService'"

**Cause**: Screen is importing the wrong AdminService

**Solution**: Update the import to match the required service:
- Dashboard screens → import from `admin_dashboard/`
- Management screens → import from `admin/`

---

## Migration Path

### Future: Consolidate to Single Service

When the dashboard is updated to use the new API:

1. Update `AdminHomeScreen` to use new AdminService
2. Remove old admin_dashboard service
3. Remove admin_dash provider registration
4. Update imports in AdminHomeScreen

### Benefits of Current Approach

✅ No breaking changes to existing dashboard
✅ New management features work immediately
✅ Easy to test independently
✅ Clear separation of responsibilities

---

**Created**: 2024
**Status**: ✅ Active - Both services working correctly
