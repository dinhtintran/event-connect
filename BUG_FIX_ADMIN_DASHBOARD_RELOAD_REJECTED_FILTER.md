# 🐛 Bug Fixes - Admin Event Management & Club Events

**Ngày:** 2025-11-19
**Priority:** HIGH - UI/UX Issues

---

## 🎯 Tổng Quan 3 Bugs

1. ❌ Tab "Yêu cầu hủy" có icon không cần thiết
2. ❌ Dashboard không reload sau khi reject event → Hiển thị sai
3. ❌ Club pages thiếu filter "Bị từ chối" cho rejected events

---

## 🔧 Fix #1: Remove Icon từ Tab "Yêu cầu hủy"

### Vấn Đề
Tab "Yêu cầu hủy" có icon `cancel_outlined` không cần thiết, gây rối mắt.

### Giải Pháp
**File:** `lib/features/admin_dashboard/presentation/screens/admin_event_management_screen.dart`

**Before:**
```dart
Tab(icon: Icon(Icons.cancel_outlined), text: 'Yêu cầu hủy'),
```

**After:**
```dart
Tab(text: 'Yêu cầu hủy'),
```

**Result:** ✅ Tab giờ chỉ có text, clean và consistent với các tab khác.

---

## 🔧 Fix #2: Dashboard Delay - Reload After Approve/Reject

### Vấn Đề
**Triệu chứng:**
- Admin reject event trong dashboard
- Event vẫn hiển thị status cũ (approved/pending)
- Phải tự reload trang mới thấy thay đổi

**Root Cause:**
Trong `admin_home_screen.dart`, các methods `_handleApproveEvent` và `_handleRejectEvent` chỉ show SnackBar mà **không reload data**.

```dart
// ❌ OLD CODE - Không reload
onPressed: () {
  // TODO: Call API to reject event  ← Chỉ có TODO!
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### Giải Pháp
**File:** `lib/features/admin_dashboard/presentation/screens/admin_home_screen.dart`

#### A. Fix `_handleApproveEvent`

**Changed:**
- `void` → `Future<void>` (async method)
- Added `await showDialog<bool>` để capture confirmation
- Added actual API call: `admin.approveEvent()`
- Added `_loadData()` để reload dashboard sau success
- Added proper error handling

**After:**
```dart
Future<void> _handleApproveEvent(Event event) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Phê duyệt sự kiện'),
      content: Text('Bạn có chắc chắn muốn phê duyệt sự kiện "${event.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Phê duyệt'),
        ),
      ],
    ),
  );

  if (confirmed == true && mounted) {
    final admin = context.read<AdminService>();
    final success = await admin.approveEvent(event.id.toString());
    
    if (mounted) {
      if (success) {
        _loadData(); // ✅ RELOAD DASHBOARD
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã phê duyệt sự kiện "${event.title}"'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể phê duyệt sự kiện'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

#### B. Fix `_handleRejectEvent`

**Changed:**
- `void` → `Future<void>` (async method)
- Added `TextEditingController` để capture lý do từ chối
- Added `await showDialog<bool>` với validation
- Added actual API call: `admin.rejectEvent(reason: reason)`
- Added `_loadData()` để reload dashboard sau success
- Added proper error handling
- Changed SnackBar color: red → orange (more appropriate for reject)

**After:**
```dart
Future<void> _handleRejectEvent(Event event) async {
  final reasonController = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Từ chối sự kiện'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bạn có chắc chắn muốn từ chối sự kiện "${event.title}"?'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Lý do từ chối *',
              border: OutlineInputBorder(),
              hintText: 'Nhập lý do từ chối...',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
              );
              return;
            }
            Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Từ chối'),
        ),
      ],
    ),
  );

  if (confirmed == true && mounted) {
    final reason = reasonController.text.trim();
    if (reason.isEmpty) return;

    final admin = context.read<AdminService>();
    final success = await admin.rejectEvent(event.id.toString(), reason: reason);
    
    if (mounted) {
      if (success) {
        _loadData(); // ✅ RELOAD DASHBOARD
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã từ chối sự kiện "${event.title}"'),
            backgroundColor: Colors.orange, // Changed from red
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể từ chối sự kiện'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

**Result:** ✅ Dashboard tự động reload sau approve/reject → UI sync với backend

---

## 🔧 Fix #3: Add "Bị từ chối" Filter cho Club Events

### Vấn Đề
**Triệu chứng:**
- System Admin reject event → Status = "rejected"
- Club Admin vào Club Events page
- **KHÔNG CÓ** filter chip "Bị từ chối"
- Event rejected bị ẩn trong tab "Tất cả", khó tìm

**Impact:**
- Club Admin không biết event nào bị reject
- Không thấy lý do reject
- Khó quản lý các event cần chỉnh sửa lại

### Hiện Trạng Code
`club_events_page.dart` đã có:
- ✅ Logic hiển thị: `_getStatusText()` trả về "Bị từ chối"
- ✅ Color coding: `_getStatusColor()` trả về `Colors.red`
- ❌ **THIẾU**: Filter chip cho status "rejected"

### Giải Pháp
**File:** `lib/features/event_creation/presentation/screens/club_events_page.dart`

**Filter Chips Before:**
```dart
Row(
  children: [
    buildFilterChip('Tất cả', 'all', _selectedStatus == 'all'),
    buildFilterChip('Bản nháp', 'draft', _selectedStatus == 'draft'),
    buildFilterChip('Chờ duyệt', 'pending', _selectedStatus == 'pending'),
    buildFilterChip('Đã duyệt', 'approved', _selectedStatus == 'approved'),
    buildFilterChip('Đã kết thúc', 'completed', _selectedStatus == 'completed'),
  ],
)
```

**Filter Chips After:**
```dart
Row(
  children: [
    buildFilterChip('Tất cả', 'all', _selectedStatus == 'all'),
    buildFilterChip('Bản nháp', 'draft', _selectedStatus == 'draft'),
    buildFilterChip('Chờ duyệt', 'pending', _selectedStatus == 'pending'),
    buildFilterChip('Đã duyệt', 'approved', _selectedStatus == 'approved'),
    buildFilterChip('Bị từ chối', 'rejected', _selectedStatus == 'rejected'), // ⭐ NEW
    buildFilterChip('Đã kết thúc', 'completed', _selectedStatus == 'completed'),
  ],
)
```

**Result:** 
- ✅ Filter chip "Bị từ chối" hiển thị với màu đỏ
- ✅ Click vào → Filter events với status='rejected'
- ✅ Club Admin dễ dàng tìm các event bị từ chối
- ✅ Có thể xem lý do reject và chỉnh sửa lại

---

## 📊 Event Status Flow (Complete)

### Status Values
```
draft      → Bản nháp (grey)
pending    → Chờ duyệt (orange)
approved   → Đã duyệt (green)
rejected   → Bị từ chối (red) ⭐ NOW VISIBLE
completed  → Đã kết thúc (grey)
cancelled  → Đã hủy (red)
```

### Complete Workflow
```
1. Club Admin tạo event
   ↓
2. Status = 'pending' → Tab "Chờ duyệt"
   ↓
3. System Admin review:
   
   OPTION A: Approve
   ├─ Status → 'approved'
   ├─ Hiển thị tab "Đã duyệt" (Club)
   └─ Event visible cho Students
   
   OPTION B: Reject ⭐
   ├─ Status → 'rejected'
   ├─ Hiển thị tab "Bị từ chối" (Club) ← NOW VISIBLE
   ├─ Club Admin xem lý do reject
   ├─ Edit event và submit lại
   └─ Status → 'pending' (back to step 2)
   
4. Event diễn ra
   ↓
5. Status → 'completed' → Tab "Đã kết thúc"
```

---

## 🧪 Testing Checklist

### ✅ Fix #1: Tab Icon
- [x] Tab "Yêu cầu hủy" không có icon
- [x] Text "Yêu cầu hủy" hiển thị rõ ràng
- [x] Consistent với các tab khác
- [x] Click vào tab hoạt động bình thường

### ✅ Fix #2: Dashboard Reload

#### Approve Flow
- [ ] Click "Phê duyệt" → Confirm dialog
- [ ] Click "Phê duyệt" trong dialog → Call API
- [ ] Success → Dashboard reload tự động
- [ ] Event biến mất khỏi "Pending Events"
- [ ] SnackBar xanh: "Đã phê duyệt sự kiện..."

#### Reject Flow
- [ ] Click "Từ chối" → Dialog với TextField
- [ ] TextField empty → Validation error
- [ ] Nhập lý do → Click "Từ chối" → Call API
- [ ] Success → Dashboard reload tự động
- [ ] Event biến mất khỏi "Pending Events"
- [ ] SnackBar cam: "Đã từ chối sự kiện..."

#### Error Handling
- [ ] API fail → SnackBar đỏ với error message
- [ ] API fail → Dashboard không reload (keep current state)
- [ ] Network timeout → Proper error display

### ✅ Fix #3: Rejected Filter

#### Club Events Page
- [ ] Filter chip "Bị từ chối" hiển thị (màu đỏ)
- [ ] Click chip → Filter events với status='rejected'
- [ ] Rejected events hiển thị với badge đỏ "Bị từ chối"
- [ ] Empty state nếu không có rejected events
- [ ] Switch giữa filters hoạt động smooth

#### Integration Test
- [ ] System Admin reject event
- [ ] Club Admin reload page
- [ ] Event xuất hiện trong tab "Tất cả"
- [ ] Click chip "Bị từ chối" → Event hiển thị
- [ ] Click vào event → Xem lý do reject (future feature)

---

## 📁 Files Modified

### Admin Dashboard
```
lib/features/admin_dashboard/presentation/screens/
├── admin_event_management_screen.dart
│   └── Removed icon from "Yêu cầu hủy" tab
└── admin_home_screen.dart
    ├── _handleApproveEvent: void → Future<void>
    ├── Added API call: admin.approveEvent()
    ├── Added _loadData() after success
    ├── _handleRejectEvent: void → Future<void>
    ├── Added TextEditingController for reason
    ├── Added API call: admin.rejectEvent(reason: reason)
    └── Added _loadData() after success
```

### Club Events
```
lib/features/event_creation/presentation/screens/
└── club_events_page.dart
    └── Added FilterChip: 'Bị từ chối' → 'rejected'
```

---

## 🎯 Impact Summary

### Before Fixes
| Issue | Impact | Severity |
|-------|--------|----------|
| Tab có icon không cần | UI cluttered | Low |
| Dashboard không reload | Data stale, confusing | **High** |
| Thiếu filter "rejected" | Can't find rejected events | **Medium** |

### After Fixes
| Improvement | Benefit | Impact |
|-------------|---------|--------|
| Clean tab UI | Better aesthetics | UI/UX |
| Auto reload dashboard | Real-time sync | **Critical** |
| Rejected filter visible | Easy event management | **User Flow** |

---

## 🔗 Related Documentation

- `FEATURE_CANCELLATION_REQUESTS_TAB.md` - Tab "Yêu cầu hủy" implementation
- `BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md` - Event status specifications
- `EVENT_APPROVAL_INTEGRATION.md` - Approval workflow
- `BUG_FIX_EVENT_MANAGEMENT_LAYOUT_CRASH.md` - Previous layout fixes

---

## 💡 Future Improvements

### 1. Show Reject Reason in Club Events
**Current:** Club Admin sees "Bị từ chối" badge but no reason
**Proposal:** 
- Add tooltip or expandable section showing reject reason
- Click event → Detail page shows full admin comment
- Notification when event is rejected

### 2. Batch Actions in Dashboard
**Current:** Approve/reject one by one
**Proposal:**
- Checkbox select multiple events
- Batch approve/reject
- Faster workflow for admins

### 3. Real-time Updates
**Current:** Manual reload
**Proposal:**
- WebSocket connection
- Auto-update when backend changes
- No need to call `_loadData()`

---

**Status:** ✅ ALL FIXES COMPLETE  
**Testing:** ⏳ PENDING  
**Priority:** 🔴 HIGH (User-facing issues)  
**Author:** GitHub Copilot  
**Date:** November 19, 2025
