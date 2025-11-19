# 🔒 FIX: Sự kiện chưa phê duyệt không được hiển thị cho Student

## 🐛 Vấn đề

**Hiện tượng:**
- Club Admin tạo sự kiện mới → Status = `pending`
- Sự kiện **hiển thị ngay lập tức** trong danh sách Explore/Home của Student ❌
- Logic sai: Student có thể xem và đăng ký sự kiện chưa được phê duyệt!

**Logic đúng phải là:**
```
Tạo sự kiện → Status = 'pending'
             ↓
   System Admin phê duyệt → Status = 'approved'
             ↓
    Hiển thị cho Student ✅
```

---

## 🔍 Root Cause Analysis

### Backend API hỗ trợ filter

**File:** `event_connect_backend/event_management/views.py`

```python
class EventViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        queryset = Event.objects.select_related('club', 'created_by')
        
        # ✅ Backend HỖ TRỢ filter status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset
```

Backend cho phép:
- `GET /api/events/` → Tất cả sự kiện (pending, approved, rejected, ...)
- `GET /api/events/?status=approved` → Chỉ sự kiện đã phê duyệt ✅
- `GET /api/events/?status=pending` → Chỉ sự kiện đang chờ (for Admin)

### Frontend KHÔNG dùng filter

**File:** `lib/features/event_management/data/api/event_api.dart`

```dart
// ❌ SAI - Không filter, lấy tất cả
Future<Map<String, dynamic>> getAllEvents() async {
  final res = await dio.get('/api/events/');  // Không có ?status=approved
  return {'status': res.statusCode, 'body': res.data};
}
```

### So sánh các endpoints

| Endpoint | Filter status? | Sử dụng |
|----------|----------------|---------|
| `/api/events/featured/` | ✅ `status='approved'` | OK - Chỉ lấy approved |
| `/api/events/search/` | ✅ `status='approved'` | OK - Chỉ lấy approved |
| `/api/events/` | ❌ Không filter | SAI - Lấy tất cả! |
| `/api/events/?category=X` | ❌ Không filter | SAI - Lấy tất cả! |

---

## ✅ Giải pháp

Thêm `?status=approved` vào tất cả API calls cho Student.

### 1. Fix getAllEvents()

**File:** `lib/features/event_management/data/api/event_api.dart`

```dart
/// GET /api/events/?status=approved - Lấy danh sách sự kiện đã được phê duyệt
/// Chỉ hiển thị sự kiện có status='approved' cho student
Future<Map<String, dynamic>> getAllEvents() async {
  _dbg('GET /api/events/?status=approved');
  try {
    final res = await dio.get('/api/events/', queryParameters: {
      'status': 'approved',  // ✅ Chỉ lấy sự kiện đã phê duyệt
    });
    _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
    return {'status': res.statusCode, 'body': res.data};
  } catch (e) {
    // ... error handling
  }
}
```

### 2. Fix getEventsByCategory()

```dart
/// GET /api/events/?category={category}&status=approved
Future<Map<String, dynamic>> getEventsByCategory(String category) async {
  _dbg('GET /api/events/?category=$category&status=approved');
  try {
    final res = await dio.get('/api/events/', queryParameters: {
      'category': category,
      'status': 'approved',  // ✅ Chỉ lấy sự kiện đã phê duyệt
    });
    return {'status': res.statusCode, 'body': res.data};
  } catch (e) {
    // ... error handling
  }
}
```

---

## 📊 So sánh Before/After

### Before Fix ❌

```dart
// Không filter
GET /api/events/
GET /api/events/?category=music

// Response: Tất cả sự kiện (pending, approved, rejected, cancelled)
[
  { "id": 1, "status": "approved" },   // OK
  { "id": 2, "status": "pending" },    // ❌ Hiển thị cho student!
  { "id": 3, "status": "rejected" },   // ❌ Hiển thị cho student!
  { "id": 4, "status": "cancelled" }   // ❌ Hiển thị cho student!
]
```

### After Fix ✅

```dart
// Có filter status=approved
GET /api/events/?status=approved
GET /api/events/?category=music&status=approved

// Response: Chỉ sự kiện đã phê duyệt
[
  { "id": 1, "status": "approved" },   // ✅ OK
  { "id": 5, "status": "approved" },   // ✅ OK
]

// Các sự kiện pending/rejected/cancelled KHÔNG hiển thị cho student
```

---

## 🔐 Security & Business Logic

### Event Status Flow

```
┌─────────────┐
│   draft     │  Club Admin đang soạn thảo
└──────┬──────┘
       │ submit
       ↓
┌─────────────┐
│  pending    │  Đang chờ System Admin phê duyệt
└──────┬──────┘  🔒 KHÔNG hiển thị cho Student
       │
       ├─ approve → ┌──────────┐
       │            │ approved │  ✅ Hiển thị cho Student
       │            └──────────┘
       │
       └─ reject  → ┌──────────┐
                    │ rejected │  🔒 KHÔNG hiển thị cho Student
                    └──────────┘
```

### Permission Matrix

| User Role | Xem Pending | Xem Approved | Xem Rejected |
|-----------|-------------|--------------|--------------|
| **Student** | ❌ NO | ✅ YES | ❌ NO |
| **Club Admin** | ✅ YES (own) | ✅ YES | ✅ YES (own) |
| **System Admin** | ✅ YES (all) | ✅ YES (all) | ✅ YES (all) |

### Why This Matters

1. **Content Moderation**: System Admin phải kiểm tra nội dung trước khi publish
2. **Quality Control**: Đảm bảo sự kiện đạt tiêu chuẩn
3. **Safety**: Tránh sự kiện spam/không phù hợp
4. **Business Rules**: Tuân thủ quy trình phê duyệt của trường

---

## 🧪 Testing

### Test Case 1: Tạo sự kiện mới

1. **Login với Club Admin**
2. **Tạo sự kiện mới** → Status = `pending`
3. **Logout → Login với Student**
4. **Vào Explore/Home**

**Expected:**
- ❌ Sự kiện vừa tạo **KHÔNG hiển thị** trong danh sách
- ✅ Chỉ hiển thị các sự kiện đã được phê duyệt

### Test Case 2: Phê duyệt sự kiện

1. **Login với System Admin**
2. **Vào Event Management → Pending Approval**
3. **Phê duyệt sự kiện** → Status = `approved`
4. **Logout → Login với Student**
5. **Vào Explore/Home**

**Expected:**
- ✅ Sự kiện vừa phê duyệt **HIỂN THỊ** trong danh sách
- ✅ Student có thể xem chi tiết và đăng ký

### Test Case 3: Filter by category

1. **Login với Student**
2. **Vào Explore → Chọn category "Music"**
3. **Kiểm tra danh sách**

**Expected:**
- ✅ Chỉ hiển thị sự kiện Music **VÀ** status='approved'
- ❌ Không hiển thị sự kiện Music nhưng status='pending'

### Test Backend API

```bash
# Test không filter (admin endpoint)
curl -X GET "http://127.0.0.1:8000/api/events/" \
  -H "Authorization: Bearer <admin_token>"

# Response: Tất cả sự kiện (pending, approved, rejected, ...)

# Test có filter (student endpoint)
curl -X GET "http://127.0.0.1:8000/api/events/?status=approved"

# Response: Chỉ sự kiện approved
```

---

## 📝 Files Changed

| File | Change | Impact |
|------|--------|--------|
| `event_api.dart` | ✅ getAllEvents() thêm `status=approved` | Explore, Home screens |
| `event_api.dart` | ✅ getEventsByCategory() thêm `status=approved` | Category filter |

**Endpoints đã có filter đúng:**
- ✅ `/api/events/featured/` - Backend filter sẵn
- ✅ `/api/events/search/` - Backend filter sẵn

---

## 🎯 Impact Analysis

### Trước khi fix:

**Security Issue:**
- Student có thể xem sự kiện chưa được kiểm duyệt
- Có thể đăng ký sự kiện spam/không phù hợp
- Bypass quy trình phê duyệt

**Business Logic Issue:**
- Vai trò System Admin vô nghĩa
- Không tuân thủ workflow: Draft → Pending → Approved

### Sau khi fix:

**Security:**
- ✅ Student chỉ xem sự kiện đã được phê duyệt
- ✅ Content moderation hoạt động đúng

**Business Logic:**
- ✅ Workflow đúng: Tạo → Chờ duyệt → Phê duyệt → Hiển thị
- ✅ System Admin có quyền kiểm soát nội dung

---

## 🚀 Deployment

1. ✅ Code changes committed
2. 🔄 **Hot reload Flutter app**
3. 🧪 **Test workflow**:
   - Tạo sự kiện mới (Club Admin)
   - Verify không hiển thị (Student)
   - Phê duyệt (System Admin)
   - Verify hiển thị (Student)

---

## 💡 Lessons Learned

### 1. Always check query parameters
Backend hỗ trợ filter nhưng Frontend phải dùng đúng cách.

### 2. Business logic phải nhất quán
Nếu có quy trình phê duyệt thì phải enforce ở mọi nơi.

### 3. Test với nhiều user roles
Bug này chỉ phát hiện được khi test cross-role:
- Tạo sự kiện (Club Admin)
- Kiểm tra hiển thị (Student)

### 4. API documentation cần rõ ràng
Cần document rõ:
- Endpoint nào public (không cần filter)
- Endpoint nào cần filter `status=approved`

---

**Fixed by:** GitHub Copilot  
**Date:** November 18, 2025  
**Status:** ✅ FIXED & READY FOR TESTING

**Related Files:**
- `event_api.dart` - API client với filter status
- `views.py` - Backend EventViewSet với filter support
