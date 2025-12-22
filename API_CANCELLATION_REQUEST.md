# API Documentation - Event Cancellation Request

## 📋 Tổng quan

Tính năng cho phép Club Admin yêu cầu hủy sự kiện đã được phê duyệt, và System Admin xét duyệt yêu cầu.

## 🔐 Authentication

Tất cả API đều yêu cầu Bearer Token trong header:
```
Authorization: Bearer <access_token>
```

---

## 📍 API Endpoints

### 1. Club Admin APIs

#### 1.1. Tạo yêu cầu hủy sự kiện

**Endpoint:** `POST /api/events/{event_id}/request_cancellation/`

**Permission:** Club Admin (President/Admin) hoặc Event Creator

**Request Body:**
```json
{
  "reason": "Lý do hủy sự kiện (tối thiểu 20 ký tự)",
  "refund_policy": "Chính sách hoàn tiền cho người tham gia (optional)",
  "alternative_action": "Hành động thay thế như hoãn, đổi địa điểm (optional)"
}
```

**Success Response (201 Created):**
```json
{
  "id": 1,
  "event": {
    "id": 5,
    "title": "Tech Conference 2025"
  },
  "status": "pending",
  "reason": "Do thời tiết xấu, chúng tôi không thể tổ chức sự kiện ngoài trời",
  "created_at": "2025-11-17T10:30:00Z",
  "message": "Cancellation request submitted successfully"
}
```

**Error Responses:**

**403 Forbidden** - Không có quyền:
```json
{
  "error": "Only club admin can request event cancellation"
}
```

**400 Bad Request** - Sự kiện không phải approved:
```json
{
  "error": "Can only request cancellation for approved events",
  "current_status": "draft"
}
```

**400 Bad Request** - Sự kiện đã kết thúc:
```json
{
  "error": "Cannot cancel past events"
}
```

**400 Bad Request** - Đã có yêu cầu pending:
```json
{
  "error": "Already has pending cancellation request",
  "request_id": 1,
  "created_at": "2025-11-17T10:00:00Z"
}
```

**400 Bad Request** - Lý do quá ngắn:
```json
{
  "reason": ["Reason must be at least 20 characters"]
}
```

---

#### 1.2. Xem yêu cầu hủy của sự kiện

**Endpoint:** `GET /api/events/{event_id}/cancellation_requests/`

**Permission:** Club Admin (President/Admin) hoặc Event Creator hoặc System Admin

**Success Response (200 OK):**
```json
{
  "event_id": 5,
  "event_title": "Tech Conference 2025",
  "count": 2,
  "results": [
    {
      "id": 2,
      "event": {
        "id": 5,
        "title": "Tech Conference 2025",
        "club": {
          "id": 1,
          "name": "Tech Club"
        },
        "status": "approved"
      },
      "requested_by": {
        "id": 10,
        "username": "club_admin",
        "email": "admin@techclub.com",
        "full_name": "Nguyễn Văn A"
      },
      "reason": "Do thời tiết xấu, chúng tôi không thể tổ chức sự kiện ngoài trời",
      "refund_policy": "Hoàn 100% tiền vé cho người tham gia",
      "alternative_action": "Hoãn sang tháng sau",
      "status": "pending",
      "reviewed_by": null,
      "reviewed_at": null,
      "admin_comment": "",
      "created_at": "2025-11-17T10:30:00Z",
      "updated_at": "2025-11-17T10:30:00Z"
    },
    {
      "id": 1,
      "event": {
        "id": 5,
        "title": "Tech Conference 2025"
      },
      "requested_by": {
        "id": 10,
        "username": "club_admin",
        "email": "admin@techclub.com",
        "full_name": "Nguyễn Văn A"
      },
      "reason": "Không đủ người đăng ký",
      "refund_policy": "",
      "alternative_action": "",
      "status": "rejected",
      "reviewed_by": {
        "id": 1,
        "username": "system_admin",
        "email": "admin@system.com"
      },
      "reviewed_at": "2025-11-17T09:00:00Z",
      "admin_comment": "Sự kiện vẫn có thể tổ chức được",
      "created_at": "2025-11-16T14:00:00Z",
      "updated_at": "2025-11-17T09:00:00Z"
    }
  ]
}
```

**Error Response (403 Forbidden):**
```json
{
  "error": "Permission denied"
}
```

---

### 2. System Admin APIs

#### 2.1. Lấy tất cả yêu cầu hủy

**Endpoint:** `GET /api/event-cancellation-requests/`

**Permission:** System Admin only

**Query Parameters:**
- `page` - Trang (default: 1)
- `page_size` - Số items mỗi trang (default: 10)

**Success Response (200 OK):**
```json
{
  "count": 15,
  "next": "http://127.0.0.1:8000/api/event-cancellation-requests/?page=2",
  "previous": null,
  "results": [
    {
      "id": 3,
      "event": {
        "id": 7,
        "title": "Workshop Python",
        "club": {
          "id": 2,
          "name": "Programming Club"
        }
      },
      "requested_by": {
        "id": 15,
        "username": "prog_admin",
        "email": "admin@progclub.com",
        "full_name": "Trần Thị B"
      },
      "reason": "Giảng viên bị ốm không thể tham gia",
      "refund_policy": "Hoàn tiền 100%",
      "alternative_action": "Đổi giảng viên hoặc hoãn",
      "status": "pending",
      "reviewed_by": null,
      "reviewed_at": null,
      "admin_comment": "",
      "created_at": "2025-11-17T11:00:00Z",
      "updated_at": "2025-11-17T11:00:00Z"
    }
  ]
}
```

---

#### 2.2. Lấy yêu cầu hủy pending

**Endpoint:** `GET /api/event-cancellation-requests/pending/`

**Permission:** System Admin only

**Success Response (200 OK):**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 3,
      "event": {
        "id": 7,
        "title": "Workshop Python"
      },
      "requested_by": {
        "id": 15,
        "username": "prog_admin",
        "email": "admin@progclub.com",
        "full_name": "Trần Thị B"
      },
      "reason": "Giảng viên bị ốm không thể tham gia",
      "status": "pending",
      "created_at": "2025-11-17T11:00:00Z"
    }
  ]
}
```

---

#### 2.3. Xét duyệt yêu cầu hủy

**Endpoint:** `POST /api/event-cancellation-requests/{id}/review/`

**Permission:** System Admin only

**Request Body (Approve):**
```json
{
  "action": "approve",
  "admin_comment": "Đồng ý hủy do lý do thời tiết hợp lý"
}
```

**Request Body (Reject):**
```json
{
  "action": "reject",
  "admin_comment": "Sự kiện vẫn có thể tổ chức được (REQUIRED khi reject)"
}
```

**Success Response - Approve (200 OK):**
```json
{
  "message": "Cancellation request approved - Event has been cancelled",
  "event_id": 7,
  "status": "cancelled",
  "notified_participants": 45
}
```

**Success Response - Reject (200 OK):**
```json
{
  "message": "Cancellation request rejected - Event will continue",
  "event_id": 7,
  "status": "approved",
  "admin_comment": "Sự kiện vẫn có thể tổ chức được"
}
```

**Error Responses:**

**400 Bad Request** - Đã được xét duyệt:
```json
{
  "error": "This cancellation request has already been reviewed",
  "detail": "Current status is \"approved\". Only pending requests can be reviewed.",
  "current_status": "approved",
  "reviewed_at": "2025-11-17T19:26:21.123456Z",
  "reviewed_by": "admin@example.com",
  "admin_comment": "Approved for testing"
}
```

**💡 Note:** Nếu nhận được lỗi này, hãy:
- Kiểm tra lại `current_status` trong response
- Chỉ call review endpoint với requests có `status="pending"`
- Sử dụng endpoint GET `/api/event-cancellation-requests/pending/` để lấy danh sách requests chưa được xét duyệt

**400 Bad Request** - Thiếu admin_comment khi reject:
```json
{
  "admin_comment": ["Admin comment is required when rejecting"]
}
```

**400 Bad Request** - Action không hợp lệ:
```json
{
  "action": ["\"invalid\" is not a valid choice."]
}
```

---

## 📊 Workflow

### Flow 1: Club Admin tạo yêu cầu hủy

```
1. Club Admin tạo yêu cầu hủy
   POST /api/events/5/request_cancellation/

2. Backend tạo EventCancellationRequest với status='pending'

3. Backend gửi notification cho tất cả System Admin

4. Trả về response với thông tin yêu cầu
```

### Flow 2: System Admin xét duyệt (Approve)

```
1. System Admin xem danh sách yêu cầu pending
   GET /api/event-cancellation-requests/pending/

2. System Admin approve yêu cầu
   POST /api/event-cancellation-requests/3/review/
   { "action": "approve", "admin_comment": "OK" }

3. Backend:
   - Update cancellation_request.status = 'approved'
   - Update event.status = 'cancelled'
   - Gửi notification cho TẤT CẢ người đăng ký sự kiện
   - Gửi notification cho Club Admin (người yêu cầu)

4. Trả về response với số người được thông báo
```

### Flow 3: System Admin xét duyệt (Reject)

```
1. System Admin reject yêu cầu
   POST /api/event-cancellation-requests/3/review/
   { "action": "reject", "admin_comment": "Lý do không hợp lý" }

2. Backend:
   - Update cancellation_request.status = 'rejected'
   - Event vẫn giữ nguyên status='approved'
   - Gửi notification cho Club Admin (người yêu cầu)

3. Trả về response
```

---

## 🔔 Notification Types

### 1. cancellation_request
- **Người nhận:** System Admin
- **Khi nào:** Club Admin tạo yêu cầu hủy
- **Title:** "Yêu cầu hủy sự kiện"
- **Message:** "CLB "{club_name}" yêu cầu hủy sự kiện "{event_title}""

### 2. cancellation_approved
- **Người nhận:** Club Admin (người yêu cầu)
- **Khi nào:** System Admin approve yêu cầu
- **Title:** "Yêu cầu hủy được chấp nhận"
- **Message:** "Yêu cầu hủy sự kiện "{event_title}" đã được phê duyệt"

### 3. cancellation_rejected
- **Người nhận:** Club Admin (người yêu cầu)
- **Khi nào:** System Admin reject yêu cầu
- **Title:** "Yêu cầu hủy bị từ chối"
- **Message:** "Yêu cầu hủy sự kiện "{event_title}" bị từ chối. Lý do: {admin_comment}"

### 4. event_cancelled
- **Người nhận:** Tất cả người đăng ký sự kiện (registered, attended)
- **Khi nào:** System Admin approve yêu cầu hủy
- **Title:** "Sự kiện bị hủy"
- **Message:** "Sự kiện "{event_title}" đã bị hủy. Lý do: {cancellation_reason}"

---

## 🧪 Testing Examples

### Test 1: Club Admin tạo yêu cầu hủy thành công

```bash
curl -X POST http://127.0.0.1:8000/api/events/5/request_cancellation/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Do thời tiết xấu, chúng tôi không thể tổ chức sự kiện ngoài trời",
    "refund_policy": "Hoàn 100% tiền vé",
    "alternative_action": "Hoãn sang tháng sau"
  }'
```

### Test 2: System Admin xem yêu cầu pending

```bash
curl -X GET http://127.0.0.1:8000/api/event-cancellation-requests/pending/ \
  -H "Authorization: Bearer SYSTEM_ADMIN_TOKEN"
```

### Test 3: System Admin approve yêu cầu

```bash
curl -X POST http://127.0.0.1:8000/api/event-cancellation-requests/3/review/ \
  -H "Authorization: Bearer SYSTEM_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "approve",
    "admin_comment": "Đồng ý hủy do lý do thời tiết hợp lý"
  }'
```

### Test 4: System Admin reject yêu cầu

```bash
curl -X POST http://127.0.0.1:8000/api/event-cancellation-requests/3/review/ \
  -H "Authorization: Bearer SYSTEM_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "reject",
    "admin_comment": "Sự kiện vẫn có thể tổ chức được"
  }'
```

---

## ✅ Business Rules

1. ✅ Chỉ sự kiện có status='approved' mới cần yêu cầu hủy
2. ✅ Không thể yêu cầu hủy sự kiện đã kết thúc (end_at < now)
3. ✅ Một sự kiện chỉ có thể có 1 yêu cầu pending tại một thời điểm
4. ✅ Lý do hủy phải có tối thiểu 20 ký tự
5. ✅ Admin comment bắt buộc khi reject
6. ✅ Khi approve: Event status → 'cancelled', tất cả participants được thông báo
7. ✅ Khi reject: Event status không đổi, chỉ club admin được thông báo
8. ✅ Chỉ Club Admin (president/admin) hoặc Event Creator mới có quyền tạo yêu cầu
9. ✅ Chỉ System Admin mới có quyền xét duyệt

---

## 🎯 Frontend Integration Guide

### 1. Kiểm tra điều kiện hiển thị nút "Yêu cầu hủy"

```dart
bool canRequestCancellation(Event event) {
  // Chỉ hiển thị cho sự kiện approved
  if (event.status != 'approved') return false;
  
  // Không hiển thị cho sự kiện đã kết thúc
  if (event.endAt.isBefore(DateTime.now())) return false;
  
  // User phải là club admin
  if (!isClubAdmin) return false;
  
  return true;
}
```

### 2. UI Flow cho Club Admin

```dart
// Button: Yêu cầu hủy sự kiện
ElevatedButton(
  onPressed: () => showCancellationDialog(event),
  child: Text('Yêu cầu hủy sự kiện'),
)

// Dialog nhập lý do
Future<void> showCancellationDialog(Event event) {
  // Show dialog với:
  // - TextField cho reason (required, min 20 chars)
  // - TextField cho refund_policy (optional)
  // - TextField cho alternative_action (optional)
  // - Button Submit
}

// Gọi API
await eventApi.requestCancellation(
  eventId: event.id,
  reason: reasonController.text,
  refundPolicy: refundController.text,
  alternativeAction: alternativeController.text,
);

// Show success message
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Đã gửi yêu cầu hủy sự kiện')),
);
```

### 3. UI Flow cho System Admin

```dart
// Trang danh sách yêu cầu pending
@override
void initState() {
  super.initState();
  _loadPendingRequests();
}

Future<void> _loadPendingRequests() async {
  final response = await cancellationApi.getPendingRequests();
  setState(() {
    requests = response.results;
  });
}

// Card hiển thị yêu cầu
CancellationRequestCard(
  request: request,
  onApprove: () => _reviewRequest(request, 'approve'),
  onReject: () => _showRejectDialog(request),
)

// Review request
Future<void> _reviewRequest(request, action) async {
  String? comment;
  if (action == 'reject') {
    comment = await _showCommentDialog(); // Required
    if (comment == null || comment.isEmpty) return;
  }
  
  await cancellationApi.reviewRequest(
    requestId: request.id,
    action: action,
    adminComment: comment,
  );
  
  _loadPendingRequests(); // Reload list
}
```

---

## 📱 API Client Examples (Dart/Flutter)

```dart
class CancellationApi {
  final Dio dio;
  
  // Club Admin: Tạo yêu cầu hủy
  Future<Map<String, dynamic>> requestCancellation({
    required String eventId,
    required String reason,
    String? refundPolicy,
    String? alternativeAction,
  }) async {
    final response = await dio.post(
      '/api/events/$eventId/request_cancellation/',
      data: {
        'reason': reason,
        if (refundPolicy != null) 'refund_policy': refundPolicy,
        if (alternativeAction != null) 'alternative_action': alternativeAction,
      },
    );
    return response.data;
  }
  
  // Club Admin: Xem yêu cầu của sự kiện
  Future<List<CancellationRequest>> getEventCancellationRequests(String eventId) async {
    final response = await dio.get('/api/events/$eventId/cancellation_requests/');
    return (response.data['results'] as List)
        .map((json) => CancellationRequest.fromJson(json))
        .toList();
  }
  
  // System Admin: Lấy yêu cầu pending
  Future<List<CancellationRequest>> getPendingRequests() async {
    final response = await dio.get('/api/event-cancellation-requests/pending/');
    return (response.data['results'] as List)
        .map((json) => CancellationRequest.fromJson(json))
        .toList();
  }
  
  // System Admin: Xét duyệt
  Future<Map<String, dynamic>> reviewRequest({
    required int requestId,
    required String action, // 'approve' | 'reject'
    String? adminComment,
  }) async {
    final response = await dio.post(
      '/api/event-cancellation-requests/$requestId/review/',
      data: {
        'action': action,
        if (adminComment != null) 'admin_comment': adminComment,
      },
    );
    return response.data;
  }
}
```

---

## 🎨 UI/UX Recommendations

### Club Admin View

1. **Button "Yêu cầu hủy"**: Hiển thị trong event detail page, màu đỏ/warning
2. **Dialog form**: Rõ ràng, có validation, placeholder hướng dẫn
3. **Confirmation**: Có dialog xác nhận trước khi submit
4. **Status tracking**: Hiển thị trạng thái yêu cầu (pending/approved/rejected)

### System Admin View

1. **Dashboard**: Badge hiển thị số yêu cầu pending
2. **List view**: Hiển thị thông tin event, club, reason, ngày tạo
3. **Detail view**: Full info + action buttons (Approve/Reject)
4. **Confirmation**: Confirm dialog với preview impact (số participants)
5. **Comment required**: Highlight required field khi reject

---

Tất cả API đã sẵn sàng! 🚀
