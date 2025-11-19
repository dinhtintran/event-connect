# ✨ Feature: Event Management Screen với 3 Tabs

## 🎯 **Tổng quan**

Đã refactor trang **Approval** thành **Event Management** - một màn hình tổng hợp để System Admin quản lý tất cả sự kiện với 3 tabs:

### **📑 3 Tabs**:
1. **Chờ duyệt** (Pending Approval) - Sự kiện chờ phê duyệt
2. **Đã duyệt** (Approved Events) - Sự kiện đã được phê duyệt
3. **Yêu cầu hủy** (Cancellation Requests) - Yêu cầu hủy sự kiện từ Club Admin

---

## 📝 **Changes Summary**

### **1️⃣ Backend Integration**

#### **AdminRepository** (`lib/features/admin_dashboard/domain/repositories/admin_repository.dart`)

**Added new methods**:

```dart
/// Get approved events
Future<Map<String, dynamic>> getApprovedEvents({int page = 1}) async {
  final uri = Uri.parse('${AppConfig.apiBaseUrl}api/events/?status=approved&page=$page');
  // ... HTTP GET request
}

/// Get pending cancellation requests
Future<Map<String, dynamic>> getPendingCancellationRequests() async {
  final uri = Uri.parse('${AppConfig.apiBaseUrl}api/event-cancellation-requests/pending/');
  // ... HTTP GET request
}

/// Review cancellation request (approve or reject)
Future<Map<String, dynamic>> reviewCancellationRequest({
  required int requestId,
  required String action, // 'approve' | 'reject'
  String? adminComment,
}) async {
  final uri = Uri.parse('${AppConfig.apiBaseUrl}api/event-cancellation-requests/$requestId/review/');
  final body = {
    'action': action,
    if (adminComment != null) 'admin_comment': adminComment,
  };
  // ... HTTP POST request
}
```

#### **AdminService** (`lib/features/admin_dashboard/domain/services/admin_service.dart`)

**Added service methods**:

```dart
/// Fetch approved events
Future<Map<String, dynamic>> fetchApprovedEvents({int page = 1}) async {
  return await _repo.getApprovedEvents(page: page);
}

/// Fetch pending cancellation requests
Future<Map<String, dynamic>> fetchPendingCancellationRequests() async {
  return await _repo.getPendingCancellationRequests();
}

/// Review cancellation request
Future<bool> reviewCancellationRequest({
  required int requestId,
  required String action,
  String? adminComment,
}) async {
  final response = await _repo.reviewCancellationRequest(
    requestId: requestId,
    action: action,
    adminComment: adminComment,
  );
  return response['status'] == 200;
}
```

---

### **2️⃣ New Screen: EventManagementScreen**

**File**: `lib/features/event_approval/presentation/screens/event_management_screen.dart`

**Features**:

#### **Tab 1: Pending Approval** 
- Hiển thị danh sách sự kiện chờ duyệt
- Actions: **Approve** hoặc **Reject**
- Dialog nhập lý do (bắt buộc khi reject, optional khi approve)
- Pull-to-refresh
- Empty state với icon + message

#### **Tab 2: Approved Events**
- Hiển thị danh sách sự kiện đã được phê duyệt
- Read-only cards (không có actions)
- Hiển thị status badge "Đã phê duyệt" màu xanh
- Pull-to-refresh
- Lazy loading (chỉ load khi user switch tab)

#### **Tab 3: Cancellation Requests**
- Hiển thị yêu cầu hủy sự kiện từ Club Admin
- Hiển thị đầy đủ:
  - Lý do yêu cầu hủy
  - Chính sách hoàn tiền (nếu có)
  - Hành động thay thế (nếu có)
  - Ngày tạo yêu cầu
- Actions: **Approve** hoặc **Reject**
- Dialog nhập lý do từ chối (bắt buộc)
- Pull-to-refresh
- Lazy loading

**State Management**:
```dart
// Pending Tab
bool _isLoadingPending = true;
List<Event> _pendingEvents = [];

// Approved Tab
bool _isLoadingApproved = true;
List<Event> _approvedEvents = [];

// Cancellation Tab
bool _isLoadingCancellations = true;
List<EventCancellationRequest> _cancellationRequests = [];
```

**Tab Controller**:
```dart
late TabController _tabController;

@override
void initState() {
  _tabController = TabController(length: 3, vsync: this);
  _tabController.addListener(_handleTabChange);
  _loadPendingEvents(); // Load first tab immediately
}

void _handleTabChange() {
  if (!_tabController.indexIsChanging) return;
  
  switch (_tabController.index) {
    case 0: _loadPendingEvents(); break;
    case 1: _loadApprovedEvents(); break;
    case 2: _loadCancellationRequests(); break;
  }
}
```

---

### **3️⃣ Routes Update**

#### **app_routes.dart**
```dart
static const String approval = '/approval'; // Deprecated
static const String eventManagement = '/event-management'; // ✨ NEW
```

#### **main.dart**
```dart
routes: {
  AppRoutes.approval: (_) => const ApprovalScreen(), // Kept for backward compatibility
  AppRoutes.eventManagement: (_) => const EventManagementScreen(), // ✨ NEW
  // ...
}
```

---

### **4️⃣ Navigation Updates**

#### **AdminHomeScreen**

**Bottom Navigation (index 1)**:
```dart
if (index == 1) {
  // Open the event management screen
  Navigator.of(context).pushReplacementNamed(AppRoutes.eventManagement);
  return;
}
```

**Quick Action Button**:
```dart
QuickActionButton(
  icon: Icons.event_note,
  label: 'Quản lý sự kiện', // Changed from "Phê duyệt sự kiện"
  onTap: () {
    Navigator.of(context).pushReplacementNamed(AppRoutes.eventManagement);
  },
),
```

---

## 🎨 **UI/UX Highlights**

### **TabBar Design**
```dart
TabBar(
  controller: _tabController,
  tabs: const [
    Tab(text: 'Chờ duyệt', icon: Icon(Icons.pending_actions)),
    Tab(text: 'Đã duyệt', icon: Icon(Icons.check_circle)),
    Tab(text: 'Yêu cầu hủy', icon: Icon(Icons.cancel_presentation)),
  ],
)
```

### **Approval/Reject Dialogs**

**Approve Event**:
```dart
AlertDialog(
  title: Text('Xác nhận phê duyệt'),
  content: Column(
    children: [
      Text('Sự kiện: "$title"'),
      TextField(labelText: 'Ghi chú (tùy chọn)'), // Optional comment
    ],
  ),
  actions: [
    TextButton('Hủy'),
    ElevatedButton('Phê duyệt', backgroundColor: Colors.green),
  ],
)
```

**Reject Event**:
```dart
AlertDialog(
  title: Text('Từ chối sự kiện'),
  content: Column(
    children: [
      Text('Sự kiện: "$title"'),
      TextField(labelText: 'Lý do từ chối *'), // Required
    ],
  ),
  actions: [
    TextButton('Hủy'),
    ElevatedButton('Từ chối', backgroundColor: Colors.red),
  ],
)
```

**Cancellation Request Cards**:
```dart
Card(
  child: Column(
    children: [
      Row(
        children: [
          Text(event.title, fontWeight: bold),
          Badge('Chờ duyệt', color: orange),
        ],
      ),
      Text('Lý do yêu cầu hủy: ...'),
      if (refundPolicy != null) Text('Chính sách hoàn tiền: ...'),
      if (alternativeAction != null) Text('Hành động thay thế: ...'),
      Row(
        children: [
          OutlinedButton('Từ chối', color: red),
          ElevatedButton('Phê duyệt', color: green),
        ],
      ),
    ],
  ),
)
```

---

## 📊 **Data Flow**

### **Pending Approval Tab**
```
User switches to tab
    ↓
_loadPendingEvents()
    ↓
AdminService.fetchPendingApprovals()
    ↓
AdminRepository.getPendingApprovals()
    ↓
GET /api/approvals/pending/
    ↓
Parse Event.fromJson()
    ↓
setState() → UI updates
```

### **Approved Events Tab**
```
User switches to tab
    ↓
_loadApprovedEvents()
    ↓
AdminService.fetchApprovedEvents()
    ↓
AdminRepository.getApprovedEvents()
    ↓
GET /api/events/?status=approved
    ↓
Parse Event.fromJson()
    ↓
setState() → UI updates
```

### **Cancellation Requests Tab**
```
User switches to tab
    ↓
_loadCancellationRequests()
    ↓
AdminService.fetchPendingCancellationRequests()
    ↓
AdminRepository.getPendingCancellationRequests()
    ↓
GET /api/event-cancellation-requests/pending/
    ↓
Parse EventCancellationRequest.fromJson()
    ↓
setState() → UI updates
```

### **Approve/Reject Cancellation**
```
User clicks approve/reject
    ↓
Show confirmation dialog
    ↓
User confirms
    ↓
AdminService.reviewCancellationRequest()
    ↓
AdminRepository.reviewCancellationRequest()
    ↓
POST /api/event-cancellation-requests/{id}/review/
Body: { action: 'approve' | 'reject', admin_comment?: string }
    ↓
Success: Show snackbar + reload tab
```

---

## 🧪 **Testing Checklist**

### **Tab 1: Pending Approval**
- [ ] Load pending events successfully
- [ ] Empty state when no events
- [ ] Approve event with comment
- [ ] Approve event without comment
- [ ] Reject event with reason
- [ ] Validation: Reject requires reason
- [ ] Pull-to-refresh works
- [ ] Success/error snackbars display

### **Tab 2: Approved Events**
- [ ] Load approved events successfully
- [ ] Empty state when no events
- [ ] Cards display correctly (read-only)
- [ ] Pull-to-refresh works
- [ ] Lazy loading (only loads on first switch)

### **Tab 3: Cancellation Requests**
- [ ] Load cancellation requests successfully
- [ ] Empty state when no requests
- [ ] Display all request fields (reason, refund, alternative)
- [ ] Approve request
- [ ] Reject request with comment
- [ ] Validation: Reject requires admin comment
- [ ] Pull-to-refresh works
- [ ] Lazy loading (only loads on first switch)

### **Navigation**
- [ ] Bottom nav "Event Management" → Opens screen
- [ ] Dashboard quick action → Opens screen
- [ ] Tab switching works smoothly
- [ ] Back navigation works
- [ ] Logout from Event Management screen

---

## 🎯 **Benefits**

### **✅ Better UX**
- Tất cả event management ở 1 chỗ
- Không cần navigation giữa nhiều screens
- Tabs switching nhanh và mượt

### **✅ Scalability**
- Dễ thêm tabs mới (Rejected, Archived, etc.)
- Reusable card widgets
- Clean separation of concerns

### **✅ Performance**
- Lazy loading: Chỉ load tab khi cần
- Pull-to-refresh cho mỗi tab
- Efficient state management

### **✅ Clean Navigation**
- Không thêm navigation items
- Backward compatible (giữ route cũ)
- Consistent navigation pattern

---

## 📂 **Files Changed**

### **New Files** ✨
- `lib/features/event_approval/presentation/screens/event_management_screen.dart`

### **Modified Files** 🔧
- `lib/features/admin_dashboard/domain/repositories/admin_repository.dart`
  - Added: `getApprovedEvents()`, `getPendingCancellationRequests()`, `reviewCancellationRequest()`
  
- `lib/features/admin_dashboard/domain/services/admin_service.dart`
  - Added: `fetchApprovedEvents()`, `fetchPendingCancellationRequests()`, `reviewCancellationRequest()`
  
- `lib/app_routes.dart`
  - Added: `AppRoutes.eventManagement`
  
- `lib/main.dart`
  - Added: Route mapping for `EventManagementScreen`
  - Import: `event_management_screen.dart`
  
- `lib/features/admin_dashboard/presentation/screens/admin_home_screen.dart`
  - Updated: Navigation to use `AppRoutes.eventManagement`
  - Updated: Quick action button label "Quản lý sự kiện"

---

## 🚀 **Next Steps (Optional Enhancements)**

### **Future Features**:
1. **Event Details Modal**
   - View full event information
   - View participant list
   - View event history

2. **Filters & Search**
   - Filter by club
   - Filter by date range
   - Search by event name

3. **Bulk Actions**
   - Select multiple events
   - Bulk approve/reject

4. **Analytics Tab**
   - Approval rate statistics
   - Average review time
   - Most active clubs

5. **Notifications**
   - Real-time notifications for new requests
   - Badge count on tab

---

## ✅ **Status**

**COMPLETED** ✅

Tính năng Event Management với 3 tabs đã hoàn thành và sẵn sàng để test!
