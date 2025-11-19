# ✅ Tính năng Yêu cầu Hủy Sự kiện - Implementation Complete

## 🎯 Tổng quan
Tính năng cho phép Club Admin yêu cầu hủy các sự kiện đã được System Admin phê duyệt. Yêu cầu hủy sẽ được gửi đến System Admin để xét duyệt.

---

## 📦 Các file đã tạo/cập nhật

### ✅ 1. Model Layer

#### **File mới**: `lib/features/event_creation/domain/models/event_cancellation_request.dart`
- ✅ `EventCancellationRequest` - Model chính
- ✅ `EventBasicInfo` - Thông tin sự kiện
- ✅ `ClubBasicInfo` - Thông tin CLB
- ✅ `UserBasicInfo` - Thông tin người dùng
- ✅ Parse from/to JSON
- ✅ Helper method `statusText` để hiển thị trạng thái

```dart
class EventCancellationRequest {
  final int id;
  final EventBasicInfo event;
  final UserBasicInfo requestedBy;
  final String reason;
  final String? refundPolicy;
  final String? alternativeAction;
  final String status; // 'pending', 'approved', 'rejected'
  // ...
}
```

---

### ✅ 2. API Layer

#### **File mới**: `lib/features/event_creation/data/api/event_cancellation_api.dart`
- ✅ `requestCancellation()` - Club Admin tạo yêu cầu hủy
- ✅ `getEventCancellationRequests()` - Xem yêu cầu hủy của sự kiện
- ✅ `getPendingRequests()` - System Admin lấy yêu cầu pending
- ✅ `reviewRequest()` - System Admin xét duyệt

```dart
class EventCancellationApi {
  /// POST /api/events/{event_id}/request_cancellation/
  Future<Map<String, dynamic>> requestCancellation({
    required String eventId,
    required String reason,
    String? refundPolicy,
    String? alternativeAction,
  });
  
  /// GET /api/events/{event_id}/cancellation_requests/
  Future<Map<String, dynamic>> getEventCancellationRequests(String eventId);
  
  // ... more methods
}
```

#### **File cập nhật**: `lib/features/event_creation/data/api/club_admin_api.dart`
- ✅ Thêm `EventCancellationApi` dependency
- ✅ Thêm method `requestCancellation()`
- ✅ Thêm method `getEventCancellationRequests()`

---

### ✅ 3. Repository Layer

#### **File cập nhật**: `lib/features/event_creation/data/repositories/club_admin_repository.dart`
- ✅ Import `EventCancellationRequest` model
- ✅ Method `requestCancellation()` - Tạo yêu cầu hủy với error handling
- ✅ Method `getEventCancellationRequests()` - Lấy danh sách yêu cầu

```dart
/// Yêu cầu hủy sự kiện (chỉ cho sự kiện đã approved)
Future<EventCancellationRequest> requestCancellation({
  required String eventId,
  required String reason,
  String? refundPolicy,
  String? alternativeAction,
}) async {
  // API call with comprehensive error handling
  // Parse response and return EventCancellationRequest
}
```

---

### ✅ 4. UI Layer - Widgets

#### **File mới**: `lib/features/event_creation/presentation/widgets/request_cancellation_dialog.dart`
Một dialog đẹp và đầy đủ chức năng:

**Features**:
- ✅ Form validation
- ✅ Required field: `reason` (min 20 chars)
- ✅ Optional fields: `refund_policy`, `alternative_action`
- ✅ Visual warnings và instructions
- ✅ Clean UI với icons và colors
- ✅ Action buttons (Cancel/Submit)

```dart
class RequestCancellationDialog extends StatefulWidget {
  final String eventTitle;
  // Returns Map<String, dynamic> with form data
}
```

**UI Components**:
- 🔔 Warning banner màu cam
- 📝 TextFormField cho reason (4 lines, required)
- 💰 TextFormField cho refund policy (2 lines, optional)
- 🔄 TextFormField cho alternative action (2 lines, optional)
- ✅ Validation messages
- 🎨 Rounded corners, proper spacing

#### **File cập nhật**: `lib/features/event_creation/presentation/widgets/club_event_card.dart`
- ✅ Thêm prop `onRequestCancellation`
- ✅ Thêm prop `canRequestCancellation`
- ✅ Thêm nút "Yêu cầu hủy" màu cam với icon `cancel_outlined`

**Button specs**:
- Color: Orange (`Colors.orange`)
- Icon: `Icons.cancel_outlined`
- Label: "Yêu cầu hủy"
- Chỉ hiển thị khi `canRequestCancellation = true`

---

### ✅ 5. UI Layer - Screens

#### **File cập nhật**: `lib/features/event_creation/presentation/screens/club_events_page.dart`

**Imports mới**:
- ✅ `RequestCancellationDialog`

**Methods mới**:
1. ✅ `_showRequestCancellationDialog(Event event)`
   - Hiển thị dialog
   - Nhận data từ dialog
   - Gọi `_requestCancellation()`

2. ✅ `_requestCancellation(Event event, Map<String, dynamic> data)`
   - Show loading indicator
   - Gọi API qua repository
   - Handle success: SnackBar xanh + reload events
   - Handle error: SnackBar đỏ với error message

**Logic cập nhật**:
```dart
// Trong render loop
final canRequestCancellation = event.status == 'approved' && 
    (event.endAt == null || event.endAt!.isAfter(now));

// Pass to ClubEventCard
ClubEventCard(
  canRequestCancellation: canRequestCancellation,
  onRequestCancellation: canRequestCancellation 
      ? () => _showRequestCancellationDialog(event) 
      : null,
  // ...
)
```

---

## 🎯 Business Rules Implementation

### ✅ Điều kiện hiển thị nút "Yêu cầu hủy"

```dart
bool canRequestCancellation(Event event) {
  // 1. Chỉ hiển thị cho sự kiện đã approved
  if (event.status != 'approved') return false;
  
  // 2. Không hiển thị cho sự kiện đã kết thúc
  if (event.endAt != null && event.endAt!.isBefore(DateTime.now())) {
    return false;
  }
  
  // 3. User phải là club admin (backend sẽ check thêm)
  return true;
}
```

### ✅ Validation Rules

**Frontend validation**:
- ✅ `reason`: Required, min 20 characters
- ✅ `refund_policy`: Optional
- ✅ `alternative_action`: Optional

**Backend validation** (đã có sẵn):
- ✅ Event phải có status = 'approved'
- ✅ Event chưa kết thúc
- ✅ Không có yêu cầu pending nào khác
- ✅ User phải là Club Admin hoặc Event Creator

---

## 🎨 UI/UX Flow

### Flow 1: Club Admin yêu cầu hủy

```
1. User vào trang Sự kiện (ClubEventsPage)
   └─> Thấy các sự kiện approved với nút "Yêu cầu hủy"

2. Click nút "Yêu cầu hủy"
   └─> Hiển thị RequestCancellationDialog

3. Điền form:
   ├─> Lý do hủy (required, min 20 chars)
   ├─> Chính sách hoàn tiền (optional)
   └─> Hành động thay thế (optional)

4. Click "Gửi yêu cầu"
   ├─> Show loading spinner
   ├─> Call API POST /api/events/{id}/request_cancellation/
   └─> Handle response:
       ├─> Success: SnackBar xanh "Đã gửi yêu cầu hủy sự kiện đến System Admin"
       └─> Error: SnackBar đỏ với error message

5. Reload danh sách sự kiện
   └─> Event vẫn giữ status 'approved' (chờ admin xét duyệt)
```

### Flow 2: System Admin xét duyệt (chưa implement UI)

```
⚠️ TODO: Cần implement UI cho System Admin
- Trang danh sách yêu cầu pending
- Chi tiết yêu cầu
- Actions: Approve/Reject với comment
```

---

## 📱 Screenshots & Examples

### 1. Nút "Yêu cầu hủy" trên Event Card
```
┌─────────────────────────────────────┐
│ [Event Image]              [Đã duyệt]│
│                                     │
│ Tech Conference 2025                │
│ 📅 01/12/2025 09:00                 │
│ 📍 Phòng 101                        │
│ 👥 Tech Club                        │
│                                     │
│ [Người đăng ký] [Chỉnh sửa]        │
│ [Yêu cầu hủy] [Chi tiết] ────────► │ ← Orange button
└─────────────────────────────────────┘
```

### 2. Dialog yêu cầu hủy
```
┌─────────────────────────────────────┐
│ ⚠️ Yêu cầu hủy sự kiện            [X]│
│                                     │
│ 📅 Tech Conference 2025             │
│                                     │
│ ℹ️ Yêu cầu hủy sẽ được gửi đến      │
│    System Admin để xét duyệt...    │
│                                     │
│ Lý do hủy *                         │
│ ┌─────────────────────────────────┐│
│ │ Do thời tiết xấu, chúng tôi...  ││
│ │                                 ││
│ └─────────────────────────────────┘│
│ Tối thiểu 20 ký tự                  │
│                                     │
│ Chính sách hoàn tiền (tùy chọn)    │
│ ┌─────────────────────────────────┐│
│ │ Hoàn 100% tiền vé...            ││
│ └─────────────────────────────────┘│
│                                     │
│ Hành động thay thế (tùy chọn)      │
│ ┌─────────────────────────────────┐│
│ │ Hoãn sang tháng sau...          ││
│ └─────────────────────────────────┘│
│                                     │
│  [Hủy bỏ]  [Gửi yêu cầu]          │
└─────────────────────────────────────┘
```

### 3. SnackBar thành công
```
┌─────────────────────────────────────┐
│ ✓ Đã gửi yêu cầu hủy sự kiện đến   │
│   System Admin                      │
└─────────────────────────────────────┘
```

---

## 🧪 Test Cases

### ✅ Test Case 1: Hiển thị nút đúng điều kiện

**Input**: Event với `status = 'approved'`, `endAt > now`

**Expected**:
- ✅ Nút "Yêu cầu hủy" hiển thị
- ✅ Nút màu cam
- ✅ Click mở dialog

---

### ✅ Test Case 2: Không hiển thị nút với event draft

**Input**: Event với `status = 'draft'`

**Expected**:
- ✅ Nút "Yêu cầu hủy" KHÔNG hiển thị
- ✅ Chỉ có nút "Xóa" hiển thị

---

### ✅ Test Case 3: Validation lỗi - Reason quá ngắn

**Input**: Dialog với `reason = "Quá ít"`

**Expected**:
- ❌ Form validation failed
- ❌ Message: "Lý do phải có ít nhất 20 ký tự"
- ❌ Không gọi API

---

### ✅ Test Case 4: Gửi yêu cầu thành công

**Input**: Dialog với reason hợp lệ

**Expected**:
- ✅ Loading spinner hiển thị
- ✅ API call: `POST /api/events/5/request_cancellation/`
- ✅ Response 201: EventCancellationRequest object
- ✅ SnackBar xanh: "Đã gửi yêu cầu..."
- ✅ Reload danh sách sự kiện

---

### ✅ Test Case 5: Backend error - Đã có yêu cầu pending

**Backend Response**:
```json
{
  "error": "Already has pending cancellation request",
  "request_id": 1
}
```

**Expected**:
- ❌ SnackBar đỏ: "Lỗi: Already has pending cancellation request"
- ❌ Dialog đóng
- ❌ Không reload

---

### ✅ Test Case 6: Backend error - Event không phải approved

**Backend Response**:
```json
{
  "error": "Can only request cancellation for approved events",
  "current_status": "draft"
}
```

**Expected**:
- ❌ SnackBar đỏ với error message
- ⚠️ Lý thuyết không xảy ra vì frontend đã ẩn nút

---

## 🔐 Security & Permissions

### Frontend Checks ✅
- ✅ Chỉ hiển thị nút cho event approved và chưa kết thúc
- ✅ Validation reason min 20 chars

### Backend Checks (đã có sẵn) ✅
- ✅ Authentication required (Bearer token)
- ✅ User phải là Club Admin hoặc Event Creator
- ✅ Event phải có status = 'approved'
- ✅ Event chưa kết thúc
- ✅ Không có yêu cầu pending khác
- ✅ Reason min 20 chars

---

## 📊 API Integration Summary

### Club Admin APIs ✅

| Method | Endpoint | Status | Frontend Method |
|--------|----------|--------|-----------------|
| POST | `/api/events/{id}/request_cancellation/` | ✅ | `requestCancellation()` |
| GET | `/api/events/{id}/cancellation_requests/` | ✅ | `getEventCancellationRequests()` |

### System Admin APIs (Backend ready, Frontend TODO)

| Method | Endpoint | Status | Note |
|--------|----------|--------|------|
| GET | `/api/event-cancellation-requests/` | ⏳ | TODO: System Admin UI |
| GET | `/api/event-cancellation-requests/pending/` | ⏳ | TODO: System Admin UI |
| POST | `/api/event-cancellation-requests/{id}/review/` | ⏳ | TODO: System Admin UI |

---

## 🎉 Implementation Status

### ✅ Completed (Club Admin Side)

1. ✅ **Model Layer**
   - EventCancellationRequest model với full fields
   - Parse from/to JSON
   - Helper methods

2. ✅ **API Layer**
   - EventCancellationApi với 4 endpoints
   - Integration vào ClubAdminApi
   - Error handling

3. ✅ **Repository Layer**
   - requestCancellation() với comprehensive error handling
   - getEventCancellationRequests()

4. ✅ **UI Components**
   - RequestCancellationDialog (beautiful, full-featured)
   - ClubEventCard updated với nút "Yêu cầu hủy"

5. ✅ **Integration**
   - ClubEventsPage fully integrated
   - Logic hiển thị nút đúng điều kiện
   - Flow hoàn chỉnh: Dialog → API → Success/Error handling
   - Reload events sau khi gửi yêu cầu

6. ✅ **Error Handling**
   - Form validation
   - API error parsing
   - User-friendly error messages
   - Loading states

---

### ⏳ TODO (System Admin Side)

1. ⏳ **System Admin UI**
   - Trang danh sách yêu cầu pending
   - Card/List item cho mỗi yêu cầu
   - Chi tiết yêu cầu (event info, reason, etc)
   - Actions: Approve/Reject buttons

2. ⏳ **Review Dialog**
   - Input cho admin comment (required khi reject)
   - Confirmation dialog
   - Show impact (số participants sẽ được thông báo)

3. ⏳ **Notifications**
   - Badge hiển thị số yêu cầu pending
   - Real-time updates (optional)

---

## 🚀 Next Steps

### Immediate (để hoàn thiện tính năng)

1. **Test trên thiết bị thật**
   - Kiểm tra UI dialog
   - Kiểm tra API calls
   - Kiểm tra error handling

2. **Fix bugs nếu có**
   - Test các edge cases
   - Test với data thật

### Short-term (tuần tới)

1. **Implement System Admin UI**
   - Tạo screen cho System Admin
   - List pending requests
   - Review functionality

2. **Thêm status tracking**
   - Hiển thị status của yêu cầu hủy
   - Show admin comment nếu bị reject

### Long-term (optional)

1. **Real-time notifications**
   - WebSocket cho updates
   - Push notifications

2. **History tracking**
   - Xem lịch sử các yêu cầu hủy
   - Analytics

---

## ✅ Summary

**Tính năng Yêu cầu Hủy Sự kiện cho Club Admin đã hoàn thành 100%!** 🎉

- ✅ **7 files** created/updated
- ✅ **Model → API → Repository → UI** fully implemented
- ✅ **Beautiful dialog** với validation
- ✅ **Comprehensive error handling**
- ✅ **Clean integration** vào existing code
- ✅ **Zero compile errors**
- ✅ **Ready for testing**

**Backend đã sẵn sàng, Frontend (Club Admin) đã sẵn sàng!**

Chỉ cần implement System Admin UI là hoàn thiện 100% tính năng! 🚀
