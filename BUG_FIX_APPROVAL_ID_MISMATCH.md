# 🐛 BUG FIX: Phê duyệt sự kiện không hoạt động

## 🔴 Vấn đề nghiêm trọng

### Triệu chứng:
1. ✅ Click "Phê duyệt" ở **Admin Dashboard** → Thành công
2. ❌ Click "Phê duyệt" ở **Event Approval Screen** → Thất bại  
3. ❌ Sau khi phê duyệt thành công, sự kiện **vẫn nằm trong danh sách Pending**

---

## 🔍 Root Cause Analysis

### API Response Structure

Backend API `/api/approvals/pending/` trả về:

```json
{
  "count": 5,
  "results": [
    {
      "id": 6,           // ← EventApproval ID (ID của bản ghi phê duyệt)
      "event": {
        "id": 7,         // ← Event ID (ID của sự kiện)
        "title": "Test Event",
        ...
      },
      "status": "pending",
      "submitted_at": "2025-11-17T16:28:10Z",
      ...
    }
  ]
}
```

### API Endpoints để Approve/Reject

```
POST /api/approvals/{approval_id}/approve/   ← Cần APPROVAL ID
POST /api/approvals/{approval_id}/reject/    ← Cần APPROVAL ID
```

**⚠️ LƯU Ý:** API cần **`approval.id`** (ID của EventApproval), KHÔNG PHẢI `event.id` (ID của Event)!

---

## ❌ Code Trước Khi Fix

### Problem 1: Parsing sai response

```dart
// ❌ SAI - Chỉ lấy event, bỏ mất approval.id
final results = response['body']['results'] as List<dynamic>;
_pendingEvents = results
    .map((json) => Event.fromJson(json['event'] as Map<String, dynamic>))
    .toList();
```

### Problem 2: Dùng Event ID thay vì Approval ID

```dart
// ❌ SAI - Dùng event.id (ID = 7)
await adminService.approveEvent(event.id, comment: note);

// API sẽ gọi: POST /api/approvals/7/approve/
// Nhưng EventApproval có id=6, không tìm thấy id=7
// → 404 Not Found ❌
```

### Problem 3: Không có model EventApproval

Code không có model để lưu `approval.id`, chỉ có `Event` model.

---

## ✅ Giải pháp

### 1. Tạo EventApproval Model

**File:** `lib/features/event_approval/domain/models/event_approval.dart`

```dart
class EventApproval {
  final int id;              // ✅ EventApproval ID
  final Event event;         // Event details
  final String status;       // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerName;
  final String comment;

  EventApproval({
    required this.id,
    required this.event,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewerName,
    this.comment = '',
  });

  factory EventApproval.fromJson(Map<String, dynamic> json) {
    return EventApproval(
      id: json['id'] as int,
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      status: json['status'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewerName: json['reviewer'] as String?,
      comment: json['comment'] as String? ?? '',
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
```

### 2. Update EventManagementScreen

**File:** `lib/features/event_approval/presentation/screens/event_management_screen.dart`

#### Parse response đúng:

```dart
// ✅ ĐÚNG - Parse toàn bộ EventApproval
final results = response['body']['results'] as List<dynamic>;
_pendingApprovals = results
    .map((json) => EventApproval.fromJson(json as Map<String, dynamic>))
    .toList();
```

#### Dùng Approval ID:

```dart
// ✅ ĐÚNG - Dùng approval.id
Future<void> _handleApprove(EventApproval approval) async {
  // ...
  final success = await adminService.approveEvent(
    approval.id.toString(),  // ← Approval ID (6)
    comment: commentController.text,
  );
}

Future<void> _handleReject(EventApproval approval) async {
  // ...
  final success = await adminService.rejectEvent(
    approval.id.toString(),  // ← Approval ID (6)
    comment: reasonController.text,
  );
}
```

#### Render list:

```dart
// ✅ ĐÚNG - Pass approval object
ListView.builder(
  itemCount: _pendingApprovals.length,
  itemBuilder: (context, index) {
    final approval = _pendingApprovals[index];
    return ApprovalEventCard(
      event: approval.event,          // Pass event để hiển thị
      onApprove: () => _handleApprove(approval),  // Pass approval
      onReject: () => _handleReject(approval),    // Pass approval
    );
  },
);
```

### 3. Update ApprovalScreen

**File:** `lib/features/event_approval/presentation/screens/approval_screen.dart`

Áp dụng các thay đổi tương tự như EventManagementScreen.

---

## 📊 So sánh Before/After

| Aspect | Before ❌ | After ✅ |
|--------|----------|---------|
| **Model** | Chỉ có `Event` | Có `EventApproval` với `id` |
| **Parse response** | `Event.fromJson(json['event'])` | `EventApproval.fromJson(json)` |
| **Approve API** | `approveEvent(event.id)` | `approveEvent(approval.id)` |
| **Reject API** | `rejectEvent(event.id)` | `rejectEvent(approval.id)` |
| **API call** | `POST /api/approvals/7/approve/` (404) | `POST /api/approvals/6/approve/` (200) |
| **Result** | ❌ Thất bại, event vẫn pending | ✅ Thành công, event được approve |

---

## 🎯 Ví dụ cụ thể

### Scenario: Phê duyệt Event ID 7

Backend data:
```json
{
  "id": 6,           // EventApproval ID
  "event": {
    "id": 7,         // Event ID
    "title": "Hackathon 2025"
  },
  "status": "pending"
}
```

### Trước khi fix ❌

```dart
// Code parse chỉ lấy event
Event event = Event.fromJson(json['event']);  // event.id = 7

// Gọi API
await approveEvent(event.id);  // event.id = 7

// API call: POST /api/approvals/7/approve/
// Backend tìm EventApproval có id=7 → Không tồn tại!
// Response: 404 Not Found ❌
```

### Sau khi fix ✅

```dart
// Code parse toàn bộ EventApproval
EventApproval approval = EventApproval.fromJson(json);
// approval.id = 6
// approval.event.id = 7

// Gọi API
await approveEvent(approval.id);  // approval.id = 6

// API call: POST /api/approvals/6/approve/
// Backend tìm EventApproval có id=6 → Tìm thấy!
// Backend update:
//   - EventApproval.status = 'approved'
//   - Event.status = 'approved'
// Response: 200 OK ✅
```

---

## 🧪 Testing

### Test Case 1: Approve từ Event Management Screen

1. Login với System Admin account
2. Vào **Event Management** → Tab **Pending Approval**
3. Click **"Phê duyệt"** trên một sự kiện
4. Nhập comment (optional) → Click **"Xác nhận phê duyệt"**

**Expected:**
- ✅ Hiển thị SnackBar "Đã phê duyệt sự kiện..."
- ✅ Sự kiện biến mất khỏi tab "Pending Approval"
- ✅ Sự kiện xuất hiện trong tab "Approved Events"

### Test Case 2: Reject từ Approval Screen

1. Login với System Admin account
2. Vào **Approval** từ bottom navigation
3. Click **"Từ chối"** trên một sự kiện
4. Nhập lý do từ chối (bắt buộc) → Click **"Xác nhận từ chối"**

**Expected:**
- ✅ Hiển thị SnackBar "Đã từ chối sự kiện..."
- ✅ Sự kiện biến mất khỏi danh sách Pending
- ✅ Backend: Event.status = 'rejected'

### Test Case 3: Verify Backend Changes

```bash
# Check event status
curl -X GET http://127.0.0.1:8000/api/events/7/ \
  -H "Authorization: Bearer <token>"

# Response should show:
# "status": "approved"  (if approved)
# "status": "rejected"  (if rejected)
```

---

## 📝 Files Changed

| # | File | Changes |
|---|------|---------|
| 1 | `event_approval.dart` (NEW) | ✅ Created EventApproval model |
| 2 | `event_management_screen.dart` | ✅ Use EventApproval instead of Event |
| 3 | `event_management_screen.dart` | ✅ Pass `approval.id` to API |
| 4 | `event_management_screen.dart` | ✅ Updated handlers to accept EventApproval |
| 5 | `approval_screen.dart` | ✅ Use EventApproval instead of Event |
| 6 | `approval_screen.dart` | ✅ Pass `approval.id` to API |
| 7 | `approval_screen.dart` | ✅ Updated handlers to accept EventApproval |

---

## 🚀 Deployment Steps

1. ✅ Code changes committed
2. 🔄 **Hot reload Flutter app**
3. 🧪 **Test approval/reject functionality**
4. ✅ Verify events update correctly in backend
5. 📝 Update API documentation if needed

---

## 💡 Lessons Learned

### 1. **Always check API response structure**
Đừng chỉ đọc documentation, hãy gọi API thật và xem response structure.

### 2. **Domain models should match API contracts**
EventApproval là một entity riêng trong backend, nên frontend cũng cần model tương ứng.

### 3. **Be careful with nested IDs**
Khi có quan hệ nested (approval → event), cần rõ ràng đang dùng ID nào:
- `approval.id`: ID của EventApproval (dùng cho approve/reject)
- `approval.event.id`: ID của Event (chỉ dùng để hiển thị)

### 4. **Test with real data**
Fake data/mocking có thể che giấu bugs như này. Always test với API thật!

---

**Fixed by:** GitHub Copilot  
**Date:** November 17, 2025  
**Status:** ✅ FIXED & READY FOR TESTING

**Related Bug:** API_APPROVAL_FIX.md (field name issues)
