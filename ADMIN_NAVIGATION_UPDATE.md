# Navigation Update - Admin System

## ✅ Thay đổi hoàn thành

### 1. Bottom Navigation Bar (System Admin)

**Trước đây (4 tabs):**
```
0. Trang Chủ (Dashboard)
1. Phê duyệt (Approval)
2. Báo cáo (Reports)
3. Hồ Sơ (Profile)
```

**Bây giờ (5 tabs):**
```
0. Trang Chủ (Dashboard)
1. User (Quản lý User) - MỚI
2. Sự kiện (Quản lý Sự kiện) - ĐỔI TÊN
3. Báo cáo (Reports)
4. Hồ Sơ (Profile)
```

### 2. Quick Actions trong Dashboard

**Trước đây:**
- Quản lý Người dùng
- Quản lý Sự kiện
- Phê duyệt Sự kiện (❌ Bị trùng với nav bar)
- Xem Báo cáo

**Bây giờ:**
- Quản lý Người dùng
- Quản lý Sự kiện
- Thống kê Chi tiết (✅ MỚI)
- Cài đặt Hệ thống (✅ MỚI)

---

## 📝 Files đã chỉnh sửa

### 1. `lib/core/widgets/app_nav_bar.dart`
**Thay đổi:**
- Thêm tab "User" (index 1)
- Đổi "Phê duyệt" thành "Sự kiện" (index 2)
- Icons: `people_outline` → `people` (active), `event_outlined` → `event` (active)

**Code:**
```dart
items = const [
  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang Chủ'),
  BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'User'),
  BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event), label: 'Sự kiện'),
  BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Báo cáo'),
  BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Hồ Sơ'),
];
```

### 2. `lib/features/admin_dashboard/presentation/screens/admin_home_screen.dart`

**Thay đổi 1: Navigation Handler**
```dart
void _onNavigationTapped(int index) {
  // 0 -> Dashboard (stay)
  // 1 -> User Management (NEW)
  // 2 -> Event Management (NEW)
  // 3 -> Reports (not implemented)
  // 4 -> Profile
  
  if (index == 1) {
    Navigator.of(context).pushNamed('/admin/users'); // NEW
  }
  if (index == 2) {
    Navigator.of(context).pushNamed('/admin/events'); // NEW
  }
  if (index == 4) {
    Navigator.of(context).pushNamed(AppRoutes.profile); // CHANGED from 3
  }
}
```

**Thay đổi 2: Quick Actions**
- Xóa: "Phê duyệt Sự kiện" (trùng với nav bar)
- Thêm: "Thống kê Chi tiết" (icon: `assessment_outlined`)
- Thêm: "Cài đặt Hệ thống" (icon: `settings_outlined`)

### 3. `lib/features/event_approval/presentation/screens/approval_screen.dart`

**Thay đổi 1: Selected Index**
```dart
int _selectedIndex = 2; // Changed from 1 (was Approval, now Event Management)
```

**Thay đổi 2: Navigation Handler**
```dart
void _onNavigationTapped(int index) {
  // 0 -> Dashboard
  // 1 -> User Management (NEW)
  // 2 -> Event Management (NEW)
  // 3 -> Reports
  // 4 -> Profile
  
  if (index == 1) {
    Navigator.of(context).pushNamed('/admin/users'); // NEW
  }
  if (index == 2) {
    Navigator.of(context).pushNamed('/admin/events'); // NEW
  }
  if (index == 4) {
    Navigator.of(context).pushNamed(AppRoutes.profile); // CHANGED from 3
  }
}
```

---

## 🎯 Mapping chi tiết

### Navigation Index Changes

| Tab | Old Index | Old Label | New Index | New Label | Route |
|-----|-----------|-----------|-----------|-----------|-------|
| Dashboard | 0 | Trang Chủ | 0 | Trang Chủ | `/admin` |
| ~~Approval~~ | ~~1~~ | ~~Phê duyệt~~ | - | - | ~~`/approval`~~ |
| **User Mgmt** | - | - | **1** | **User** | **`/admin/users`** |
| **Event Mgmt** | - | - | **2** | **Sự kiện** | **`/admin/events`** |
| Reports | 2 | Báo cáo | 3 | Báo cáo | - |
| Profile | 3 | Hồ Sơ | 4 | Hồ Sơ | `/profile` |

### Quick Actions Changes

| Old Action | Icon | New Action | Icon |
|------------|------|------------|------|
| Quản lý Người dùng | `people_outline` | Quản lý Người dùng | `people_outline` |
| Quản lý Sự kiện | `event_outlined` | Quản lý Sự kiện | `event_outlined` |
| ~~Phê duyệt Sự kiện~~ | ~~`check_circle_outline`~~ | **Thống kê Chi tiết** | **`assessment_outlined`** |
| ~~Xem Báo cáo~~ | ~~`visibility_outlined`~~ | **Cài đặt Hệ thống** | **`settings_outlined`** |

---

## 🧪 Testing Checklist

### Navigation Bar Tests
- [ ] Click "Trang Chủ" → Stay on dashboard ✅
- [ ] Click "User" → Navigate to `/admin/users` ✅
- [ ] Click "Sự kiện" → Navigate to `/admin/events` ✅
- [ ] Click "Báo cáo" → Show "Tính năng đang phát triển" ✅
- [ ] Click "Hồ Sơ" → Navigate to `/profile` ✅

### Dashboard Quick Actions Tests
- [ ] Click "Quản lý Người dùng" → Navigate to `/admin/users` ✅
- [ ] Click "Quản lý Sự kiện" → Navigate to `/admin/events` ✅
- [ ] Click "Thống kê Chi tiết" → Show snackbar ✅
- [ ] Click "Cài đặt Hệ thống" → Show snackbar ✅

### From User Management Screen
- [ ] Back button → Return to dashboard ✅
- [ ] No bottom nav bar → Correct ✅

### From Event Management Screen
- [ ] Back button → Return to dashboard ✅
- [ ] Tab switching works (All/Pending/Approved/Rejected) ✅
- [ ] No bottom nav bar → Correct ✅

### From Approval Screen (Deprecated)
- [ ] Navigation bar shows "Sự kiện" highlighted (index 2) ✅
- [ ] Click other nav items → Navigate correctly ✅

---

## 📊 User Flow

```
Admin Dashboard (index 0)
    ↓
    ├─ [Nav Bar] Click "User" (index 1)
    │       ↓
    │   User Management Screen
    │       ↓
    │   [Back Button] → Admin Dashboard
    │
    ├─ [Nav Bar] Click "Sự kiện" (index 2)
    │       ↓
    │   Event Management Screen (4 tabs)
    │       ├─ All Events
    │       ├─ Pending (Chờ duyệt)
    │       ├─ Approved (Đã duyệt)
    │       └─ Rejected (Từ chối)
    │       ↓
    │   [Back Button] → Admin Dashboard
    │
    ├─ [Quick Action] "Quản lý Người dùng"
    │       ↓
    │   → Same as Nav Bar "User"
    │
    ├─ [Quick Action] "Quản lý Sự kiện"
    │       ↓
    │   → Same as Nav Bar "Sự kiện"
    │
    └─ [Nav Bar] Click "Hồ Sơ" (index 4)
            ↓
        Profile Screen
```

---

## ✅ Benefits

1. **Consistency:** Navigation labels match actual functionality
   - "Phê duyệt" → "Sự kiện" (more comprehensive)
   - Covers approve/reject/cancel, not just approval

2. **Accessibility:** Direct access to both management screens from nav bar
   - User Management (NEW)
   - Event Management (visible)

3. **No Duplication:** Removed redundant "Phê duyệt Sự kiện" from quick actions

4. **Future-Ready:** 
   - Added "Thống kê Chi tiết" placeholder
   - Added "Cài đặt Hệ thống" placeholder

---

## 🎨 UI Impact

### Navigation Bar Icons
- **User tab:** `Icons.people_outline` / `Icons.people` (active)
- **Event tab:** `Icons.event_outlined` / `Icons.event` (active)
- **Selected color:** `Color(0xFF6366F1)` (purple-blue)

### Quick Actions Grid
- Still 2x2 grid
- Icons now: `people_outline`, `event_outlined`, `assessment_outlined`, `settings_outlined`

---

## 🔄 Migration Notes

- **Old "Phê duyệt" functionality:** Now accessed via "Sự kiện" tab
- **ApprovalScreen:** Still exists for backward compatibility, but selected index updated to 2
- **Routes unchanged:**
  - `/admin/users` → User Management
  - `/admin/events` → Event Management
  - `/approval` → Deprecated ApprovalScreen (redirects properly)

---

**Updated:** 2025-11-19
**Status:** ✅ COMPLETE
**Files Modified:** 3
**Breaking Changes:** None (backward compatible)
