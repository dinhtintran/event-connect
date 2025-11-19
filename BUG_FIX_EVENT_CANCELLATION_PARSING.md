# 🐛 Bug Fix: EventCancellationRequest Parsing Error

## ❌ Lỗi gặp phải

```
[EventCancellationApi] POST /api/events/1/request_cancellation/
[EventCancellationApi] response 201 http://127.0.0.1:8000/api/events/1/request_cancellation/
❌ Error: Type casting or parsing error (không có error message cụ thể)
```

---

## 🔍 Nguyên nhân

### Backend Response Format

Khi tạo yêu cầu hủy mới, backend trả về **response đơn giản**:

```json
{
  "id": 1,
  "event": {
    "id": 5,
    "title": "Tech Conference 2025"
  },
  "status": "pending",
  "reason": "Do thời tiết xấu...",
  "created_at": "2025-11-17T10:30:00Z",
  "message": "Cancellation request submitted successfully"
}
```

**Thiếu các fields**:
- ❌ `requested_by` (UserBasicInfo)
- ❌ `updated_at` (DateTime)
- ❌ `refund_policy` (có thể null)
- ❌ `alternative_action` (có thể null)

### Model Definition (Trước khi fix)

Model `EventCancellationRequest` **yêu cầu** các fields này:

```dart
class EventCancellationRequest {
  final UserBasicInfo requestedBy;  // ❌ Required nhưng backend không trả về
  final DateTime updatedAt;         // ❌ Required nhưng backend không trả về
  // ...
}
```

**Kết quả**: Parse JSON thất bại vì thiếu required fields.

---

## ✅ Giải pháp

### 1. Cập nhật Model - Make fields optional

**File**: `lib/features/event_creation/domain/models/event_cancellation_request.dart`

```dart
class EventCancellationRequest {
  final int id;
  final EventBasicInfo event;
  final UserBasicInfo? requestedBy;  // ✅ Optional
  final String reason;
  final String? refundPolicy;
  final String? alternativeAction;
  final String status;
  final UserBasicInfo? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminComment;
  final DateTime createdAt;
  final DateTime? updatedAt;  // ✅ Optional

  EventCancellationRequest({
    required this.id,
    required this.event,
    this.requestedBy,  // ✅ No longer required
    required this.reason,
    this.refundPolicy,
    this.alternativeAction,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.adminComment,
    required this.createdAt,
    this.updatedAt,  // ✅ No longer required
  });

  factory EventCancellationRequest.fromJson(Map<String, dynamic> json) {
    return EventCancellationRequest(
      id: json['id'] as int,
      event: EventBasicInfo.fromJson(json['event'] as Map<String, dynamic>),
      requestedBy: json['requested_by'] != null  // ✅ Check null
          ? UserBasicInfo.fromJson(json['requested_by'] as Map<String, dynamic>)
          : null,
      reason: json['reason'] as String,
      refundPolicy: json['refund_policy'] as String?,
      alternativeAction: json['alternative_action'] as String?,
      status: json['status'] as String,
      reviewedBy: json['reviewed_by'] != null 
          ? UserBasicInfo.fromJson(json['reviewed_by'] as Map<String, dynamic>)
          : null,
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      adminComment: json['admin_comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null  // ✅ Check null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
```

### 2. Cập nhật toJson() method

```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'event': event.toJson(),
    if (requestedBy != null) 'requested_by': requestedBy!.toJson(),  // ✅ Conditional
    'reason': reason,
    if (refundPolicy != null) 'refund_policy': refundPolicy,
    if (alternativeAction != null) 'alternative_action': alternativeAction,
    'status': status,
    if (reviewedBy != null) 'reviewed_by': reviewedBy!.toJson(),
    if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
    if (adminComment != null) 'admin_comment': adminComment,
    'created_at': createdAt.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),  // ✅ Conditional
  };
}
```

---

## 🎯 Tại sao Backend Response khác nhau?

### Create Response (POST)
Backend chỉ trả về **thông tin cần thiết** sau khi tạo:
- ID của request
- Event basic info
- Status (pending)
- Reason
- Created timestamp

### List Response (GET)
Backend trả về **đầy đủ thông tin**:
- Tất cả fields bao gồm `requested_by`, `updated_at`, etc.
- Dùng cho hiển thị chi tiết yêu cầu

**Giải pháp**: Model phải support cả 2 formats → Make fields optional!

---

## ✅ Kết quả sau khi fix

```
[EventCancellationApi] POST /api/events/1/request_cancellation/
[EventCancellationApi] response 201 http://127.0.0.1:8000/api/events/1/request_cancellation/
✅ Parse successful
✅ EventCancellationRequest created
✅ SnackBar: "Đã gửi yêu cầu hủy sự kiện đến System Admin"
✅ Events list reloaded
```

---

## 📝 Lessons Learned

### 1. **Always check backend response format**
- Đọc API documentation kỹ
- Test API với curl/Postman trước
- Verify response structure

### 2. **Make model flexible**
- Không phải tất cả fields đều có trong mọi response
- Create vs Get response có thể khác nhau
- Use optional fields (`?`) when appropriate

### 3. **Add debug logging**
```dart
try {
  return Model.fromJson(data);
} catch (e) {
  print('❌ Error parsing: $e');
  print('❌ Data: $data');
  rethrow;
}
```

### 4. **Handle different response scenarios**
- Create response (minimal fields)
- Get/List response (full fields)
- Error response
- Empty response

---

## 🧪 Testing Checklist

- ✅ Create cancellation request → Success
- ✅ Parse response → No errors
- ✅ Show success message → SnackBar displayed
- ✅ Reload events list → Working
- ⏳ Get cancellation requests → Need to test
- ⏳ Display request details → Need to test

---

## 🚀 Status

**FIXED** ✅

Tính năng yêu cầu hủy sự kiện giờ đã hoạt động bình thường!
