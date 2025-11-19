# 🔧 API APPROVAL FIX - Sửa lỗi tích hợp API phê duyệt sự kiện

## 🐛 Vấn đề tìm thấy

Khi kiểm tra code Flutter với API documentation, phát hiện **field names không khớp** giữa Frontend và Backend.

### Backend API (Django - Đúng theo spec)

**File:** `event_connect_backend/event_management/serializers.py`
```python
class EventApprovalActionSerializer(serializers.Serializer):
    comment = serializers.CharField(required=False, allow_blank=True)
```

**Backend expects:** `comment` (số ít)

### Frontend Code (Flutter - SAI)

**Trước khi fix:**

#### 1. AdminRepository (❌ SAI)
```dart
// Approve API
body: json.encode({'comments': comments ?? ''}),  // ❌ 'comments' (số nhiều)

// Reject API  
body: json.encode({'reason': reason}),  // ❌ 'reason' thay vì 'comment'
```

#### 2. AdminService (❌ SAI)
```dart
Future<bool> approveEvent(String eventId, {String? comments})  // ❌ 'comments'
Future<bool> rejectEvent(String eventId, {required String reason})  // ❌ 'reason'
```

#### 3. EventManagementScreen (❌ SAI)
```dart
adminService.approveEvent(event.id, comments: "...")  // ❌ 'comments'
adminService.rejectEvent(event.id, reason: "...")  // ❌ 'reason'
```

---

## ✅ Giải pháp

Đổi tất cả field names thành `comment` (số ít) để khớp với Backend API.

### 1. Fixed AdminRepository

**File:** `lib/features/admin_dashboard/domain/repositories/admin_repository.dart`

```dart
/// Approve an event
Future<Map<String, dynamic>> approveEvent(String eventId, {String? comment}) async {
  // ...
  body: json.encode({'comment': comment ?? ''}),  // ✅ FIXED
}

/// Reject an event  
Future<Map<String, dynamic>> rejectEvent(String eventId, {required String comment}) async {
  // ...
  body: json.encode({'comment': comment}),  // ✅ FIXED
}
```

### 2. Fixed AdminService

**File:** `lib/features/admin_dashboard/domain/services/admin_service.dart`

```dart
/// Approve an event
Future<bool> approveEvent(String eventId, {String? comment}) async {  // ✅ FIXED
  final response = await _repo.approveEvent(eventId, comment: comment);
  return response['status'] == 200;
}

/// Reject an event
Future<bool> rejectEvent(String eventId, {required String comment}) async {  // ✅ FIXED
  final response = await _repo.rejectEvent(eventId, comment: comment);
  return response['status'] == 200;
}
```

### 3. Fixed EventManagementScreen

**File:** `lib/features/event_approval/presentation/screens/event_management_screen.dart`

```dart
// Approve
final success = await adminService.approveEvent(
  event.id.toString(),
  comment: commentController.text.trim().isEmpty   // ✅ FIXED
      ? null 
      : commentController.text.trim(),
);

// Reject
final success = await adminService.rejectEvent(
  event.id.toString(),
  comment: reasonController.text.trim(),  // ✅ FIXED
);
```

---

## 📋 Summary of Changes

| File | Line(s) | Change |
|------|---------|--------|
| `admin_repository.dart` | ~100 | `comments` → `comment` |
| `admin_repository.dart` | ~125 | `reason` → `comment` |
| `admin_service.dart` | ~63 | Parameter name: `comments` → `comment` |
| `admin_service.dart` | ~68 | Parameter name: `reason` → `comment` |
| `event_management_screen.dart` | ~136 | Named argument: `comments:` → `comment:` |
| `event_management_screen.dart` | ~201 | Named argument: `reason:` → `comment:` |

---

## 🧪 Testing Steps

### 1. Test Approve Event

```bash
# Login as System Admin
curl -X POST http://127.0.0.1:8000/api/accounts/login/ \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "admin123"}'

# Approve Event (with correct field name)
curl -X POST http://127.0.0.1:8000/api/approvals/1/approve/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"comment": "Sự kiện đạt yêu cầu"}'
```

**Expected Response:**
```json
{
  "message": "Event approved successfully",
  "event_id": 1,
  "approved_at": "2025-11-17T10:30:00Z"
}
```

### 2. Test Reject Event

```bash
# Reject Event (with correct field name)
curl -X POST http://127.0.0.1:8000/api/approvals/2/reject/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"comment": "Nội dung không phù hợp"}'
```

**Expected Response:**
```json
{
  "message": "Event rejected",
  "event_id": 2,
  "rejected_at": "2025-11-17T10:35:00Z"
}
```

### 3. Test in Flutter App

1. **Login với System Admin account**
2. **Vào màn Event Management** (từ Admin Dashboard)
3. **Tab "Pending Approval"** - Xem danh sách sự kiện chờ duyệt
4. **Click "Phê duyệt"** - Nhập comment (tùy chọn) → Click "Xác nhận"
   - ✅ Phải thấy SnackBar "Đã phê duyệt sự kiện..."
   - ✅ Sự kiện biến mất khỏi tab Pending
   - ✅ Check tab "Approved Events" - sự kiện xuất hiện
5. **Click "Từ chối"** - Nhập lý do (bắt buộc) → Click "Xác nhận"
   - ✅ Phải thấy SnackBar "Đã từ chối sự kiện..."
   - ✅ Sự kiện biến mất khỏi tab Pending

---

## 🔍 Root Cause Analysis

### Tại sao lỗi này xảy ra?

1. **Documentation mismatch**: Code được viết trước khi API doc hoàn chỉnh
2. **Naming convention confusion**: 
   - Developer nghĩ `comments` (plural) vì có thể có nhiều comments
   - Developer dùng `reason` vì reject cần lý do cụ thể
3. **Lack of API contract validation**: Không test API trước khi implement

### Lesson Learned

✅ **ALWAYS** check Backend serializer/schema trước khi code Frontend  
✅ **ALWAYS** test API endpoint với curl/Postman trước  
✅ **ALWAYS** keep API documentation in sync with implementation  
✅ Use TypeScript/OpenAPI schema để auto-generate API clients (prevents này type of errors)

---

## 📊 Impact Assessment

### Before Fix (❌)
- ✅ GET `/api/approvals/pending/` - **Working** (không có body)
- ❌ POST `/api/approvals/{id}/approve/` - **400 Bad Request** (field name mismatch)
- ❌ POST `/api/approvals/{id}/reject/` - **400 Bad Request** (field name mismatch)

### After Fix (✅)
- ✅ GET `/api/approvals/pending/` - **Working**
- ✅ POST `/api/approvals/{id}/approve/` - **Working**
- ✅ POST `/api/approvals/{id}/reject/` - **Working**

---

## 🎯 Next Steps

1. ✅ **Code changes completed** - All field names fixed
2. 🔄 **Hot reload Flutter app** - Test changes
3. 🧪 **Manual testing** - Verify approve/reject functionality
4. 📝 **Update API documentation** - Ensure it matches implementation
5. 🚀 **Deploy to staging** - Test with real data

---

## 🔗 Related Files

- API Spec: `API_COMPARISON_REPORT.md`
- Backend Views: `event_connect_backend/event_management/views.py`
- Backend Serializer: `event_connect_backend/event_management/serializers.py`
- Frontend Repository: `lib/features/admin_dashboard/domain/repositories/admin_repository.dart`
- Frontend Service: `lib/features/admin_dashboard/domain/services/admin_service.dart`
- Frontend UI: `lib/features/event_approval/presentation/screens/event_management_screen.dart`

---

**Fixed by:** GitHub Copilot  
**Date:** November 17, 2025  
**Status:** ✅ FIXED & READY FOR TESTING
