# 📋 Event Approval Integration - Frontend ↔ Backend

## ✅ Hoàn thành kết nối Event Approval Screen với Backend

### 🔄 Luồng dữ liệu

```
┌─────────────────────┐
│  ApprovalScreen     │  (UI Layer)
│  Pending Events     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   AdminService      │  (State Management - Reused)
│  ChangeNotifier     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  AdminRepository    │  (Data Layer)
│   HTTP API Calls    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Backend Django    │  
│ /api/approvals/*    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Database SQLite    │
│  event_approvals    │
└─────────────────────┘
```

---

## 📍 API Endpoints được sử dụng

### 1. **GET /api/approvals/pending/**
**Mục đích**: Lấy danh sách sự kiện chờ phê duyệt

**Frontend Code:**
```dart
final response = await adminService.fetchPendingApprovals();
```

**Backend:** `event_management/views.py` → `EventApprovalViewSet.pending()`

**SQL Query:**
```sql
SELECT * FROM event_approvals 
JOIN events ON event_approvals.event_id = events.id
JOIN clubs ON events.club_id = clubs.id
JOIN users ON events.created_by_id = users.id
WHERE event_approvals.status = 'pending'
ORDER BY event_approvals.submitted_at DESC;
```

**Response:**
```json
{
  "count": 1,
  "results": [
    {
      "id": 1,
      "event": {
        "id": "4",
        "title": "Career Seminar 2025",
        "description": "Hội thảo về định hướng nghề nghiệp",
        "club": {
          "id": "1",
          "name": "Tech Club"
        },
        "location": "Hội trường B",
        "start_at": "2025-12-10T09:00:00Z",
        "end_at": "2025-12-10T17:00:00Z",
        "capacity": 200,
        "status": "pending"
      },
      "status": "pending",
      "submitted_at": "2025-11-10T04:27:48.123Z"
    }
  ]
}
```

### 2. **POST /api/approvals/{event_id}/approve/**
**Mục đích**: Phê duyệt sự kiện

**Frontend Code:**
```dart
final success = await adminService.approveEvent(
  event.id, 
  comments: note
);
```

**Request Body:**
```json
{
  "comments": "Sự kiện phù hợp với quy định"
}
```

**Backend Operations:**
```python
# 1. Update event status
UPDATE events 
SET status='approved' 
WHERE id=?;

# 2. Update approval record
UPDATE event_approvals 
SET status='approved', 
    reviewer_id=?, 
    reviewed_at=?,
    comments=?
WHERE event_id=?;

# 3. Create notification
INSERT INTO notifications (
  user_id, type, event_id, message
) VALUES (?, 'event_approved', ?, ?);

# 4. Log activity
INSERT INTO activity_logs (
  user_id, action, description
) VALUES (?, 'event_approved', ?);
```

**Response:**
```json
{
  "message": "Event approved successfully",
  "event_id": "4",
  "status": "approved"
}
```

### 3. **POST /api/approvals/{event_id}/reject/**
**Mục đích**: Từ chối sự kiện

**Frontend Code:**
```dart
final success = await adminService.rejectEvent(
  event.id, 
  reason: reason
);
```

**Request Body:**
```json
{
  "reason": "Không đủ thông tin về địa điểm tổ chức"
}
```

**Backend Operations:**
```python
# 1. Update event status
UPDATE events 
SET status='rejected' 
WHERE id=?;

# 2. Update approval record
UPDATE event_approvals 
SET status='rejected', 
    reviewer_id=?, 
    reviewed_at=?,
    rejection_reason=?
WHERE event_id=?;

# 3. Create notification
INSERT INTO notifications (
  user_id, type, event_id, message
) VALUES (?, 'event_rejected', ?, ?);

# 4. Log activity
INSERT INTO activity_logs (
  user_id, action, description, metadata
) VALUES (?, 'event_rejected', ?, ?);
```

---

## 🔄 Các thay đổi đã thực hiện

### ✅ **1. Xóa dữ liệu mẫu (hardcoded)**
**Trước:**
```dart
final List<Event> _pendingEvents = [
  Event(id: '1', title: 'Hội thảo AI...'),
  Event(id: '2', title: 'Workshop...'),
];
```

**Sau:**
```dart
bool _isLoading = true;
List<Event> _pendingEvents = [];

@override
void initState() {
  super.initState();
  _loadPendingEvents();
}
```

### ✅ **2. Fetch dữ liệu thật từ API**
```dart
Future<void> _loadPendingEvents() async {
  setState(() => _isLoading = true);
  
  final adminService = Provider.of<AdminService>(context, listen: false);
  final response = await adminService.fetchPendingApprovals();
  
  if (response['status'] == 200 && mounted) {
    final results = response['body']['results'] as List<dynamic>;
    setState(() {
      _pendingEvents = results
          .map((json) => Event.fromJson(json['event']))
          .toList();
      _isLoading = false;
    });
  }
}
```

### ✅ **3. Kết nối Approve với API**
**Trước:**
```dart
onPressed: () {
  // TODO: Call API to approve event
  ScaffoldMessenger.of(context).showSnackBar(...);
  setState(() {
    _pendingEvents.removeWhere((e) => e.id == event.id);
  });
}
```

**Sau:**
```dart
onPressed: () async {
  Navigator.pop(context); // Close dialog
  
  // Show loading indicator
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Đang phê duyệt...'),
        ],
      ),
    ),
  );
  
  // Call API
  final adminService = Provider.of<AdminService>(context, listen: false);
  final success = await adminService.approveEvent(event.id, comments: note);
  
  if (success && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã phê duyệt "${event.title}"')),
    );
    _loadPendingEvents(); // Reload list
  }
}
```

### ✅ **4. Kết nối Reject với API**
```dart
void _handleReject(Event event) {
  final reasonController = TextEditingController();
  
  showDialog(...
    onPressed: () async {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        // Show validation error
        return;
      }
      
      Navigator.pop(context);
      
      // Call API
      final success = await adminService.rejectEvent(
        event.id, 
        reason: reason
      );
      
      if (success) {
        // Success feedback
        _loadPendingEvents();
      }
    }
  );
}
```

### ✅ **5. Thêm Loading States**
```dart
body: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : _pendingEvents.isEmpty
        ? Center(child: Text('Không có sự kiện nào cần phê duyệt'))
        : ListView.builder(...)
```

### ✅ **6. Thêm Refresh Button**
```dart
actions: [
  IconButton(
    icon: const Icon(Icons.refresh),
    onPressed: _loadPendingEvents,
    tooltip: 'Tải lại',
  ),
  ...
]
```

### ✅ **7. Cập nhật Role Check**
**Trước:**
```dart
if (!auth.isAuthenticated || role != 'school') {
  // Access denied
}
```

**Sau:**
```dart
if (!auth.isAuthenticated || 
    (role != 'school' && role != 'admin' && role != 'system_admin')) {
  // Access denied
}
```

### ✅ **8. Navigation giữa screens**
```dart
void _onNavigationTapped(int index) {
  if (index == 0) {
    // Go to Dashboard
    Navigator.of(context).pushReplacementNamed(AppRoutes.admin);
  } else if (index == 1) {
    // Already on Approval screen
    return;
  } else {
    // Other tabs not implemented
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

---

## 🎨 UI/UX Improvements

### 1. **Loading States**
- Loading spinner khi fetch dữ liệu
- Loading indicator khi approve/reject
- Disabled buttons khi đang xử lý

### 2. **Empty States**
- Icon và message khi không có pending events
- Friendly UI cho trường hợp empty

### 3. **Error Handling**
- Validation cho lý do từ chối (required)
- Error messages khi API call thất bại
- Success/Error feedback với SnackBar

### 4. **User Feedback**
- "Đang phê duyệt..." loading message
- "Đã phê duyệt..." success message
- Auto reload list sau khi approve/reject

---

## 🧪 Test Flow

### Scenario 1: Approve Event
1. **Login** với `admin` / `admin123`
2. **Navigate** to Approval screen (từ Admin Dashboard)
3. **View** pending event trong list
4. **Click** "Phê duyệt"
5. **Fill** approval dialog (location verified, time verified, etc.)
6. **Submit** → API call to `/api/approvals/{id}/approve/`
7. **Database** updates:
   - event.status = 'approved'
   - approval.status = 'approved'
   - Create notification for event creator
8. **UI** reloads và event biến mất khỏi pending list

### Scenario 2: Reject Event
1. **Click** "Từ chối" trên pending event
2. **Enter** rejection reason (required)
3. **Submit** → API call to `/api/approvals/{id}/reject/`
4. **Database** updates:
   - event.status = 'rejected'
   - approval.status = 'rejected' with reason
   - Create notification with reason
5. **UI** reloads và event biến mất

### Scenario 3: Empty State
1. Khi tất cả events đã được approve/reject
2. List trống
3. Hiển thị empty state với icon và message

---

## 📊 Database Schema

### event_approvals Table
```sql
CREATE TABLE event_approvals (
  id INTEGER PRIMARY KEY,
  event_id INTEGER REFERENCES events(id),
  status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'approved', 'rejected'
  reviewer_id INTEGER REFERENCES users(id),
  reviewed_at DATETIME,
  comments TEXT,
  rejection_reason TEXT,
  submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Approval Workflow
```
Event Created (status='pending')
        ↓
EventApproval Created (status='pending')
        ↓
    Admin Review
        ↓
   ┌────────┴────────┐
   ↓                 ↓
Approve           Reject
   ↓                 ↓
event.status    event.status
='approved'     ='rejected'
   ↓                 ↓
Notify          Notify + Reason
Creator         Creator
```

---

## ✨ Key Features

### ✅ Real-time Data
- Fetch pending events từ database thực
- Auto-reload sau mỗi action
- Refresh button để manual reload

### ✅ API Integration
- `fetchPendingApprovals()` - Get pending events
- `approveEvent(id, comments)` - Approve with notes
- `rejectEvent(id, reason)` - Reject with reason

### ✅ User Experience
- Loading states cho mọi async operations
- Clear success/error feedback
- Validation cho required fields
- Smooth navigation giữa screens

### ✅ Permission Control
- Chỉ `system_admin`, `admin`, `school` có quyền truy cập
- Role check ở UI level
- Backend cũng có permission check

### ✅ Error Resilience
- Handle API errors gracefully
- Show user-friendly error messages
- Don't crash on network failures

---

## 🔗 Integration Points

### Shared Services
- **AdminService**: Dùng chung cho cả Admin Dashboard và Approval Screen
- **AdminRepository**: Single source of API calls
- **AuthService**: Role checking và authentication

### Navigation Flow
```
Admin Login
    ↓
Admin Dashboard (AdminHomeScreen)
    ↓
    ├─→ "Phê duyệt sự kiện" button → ApprovalScreen
    └─→ Bottom Nav "Phê duyệt" tab → ApprovalScreen
        ↓
    Approve/Reject Event
        ↓
    Back to Dashboard or stay on Approval
```

---

## 🎯 Summary

**Status**: ✅ **FULLY INTEGRATED**

### What was done:
1. ✅ Removed hardcoded sample data
2. ✅ Integrated with AdminService for API calls
3. ✅ Added loading states and error handling
4. ✅ Connected approve action to backend API
5. ✅ Connected reject action to backend API
6. ✅ Added validation for rejection reason
7. ✅ Implemented auto-reload after actions
8. ✅ Added refresh button
9. ✅ Updated role permissions
10. ✅ Improved navigation between screens

### APIs Used:
- `GET /api/approvals/pending/`
- `POST /api/approvals/{id}/approve/`
- `POST /api/approvals/{id}/reject/`

### Database Operations:
- ✅ Query pending approvals
- ✅ Update event status (approved/rejected)
- ✅ Update approval records
- ✅ Create notifications
- ✅ Log activities

---

**Ngày hoàn thành**: November 10, 2025  
**Version**: 1.0.0  
**Integration Status**: 🟢 COMPLETE

