# 🔴 BUG REPORT: Admin Event Management 404 Error

## Triệu chứng
```
GET /api/admin/events/?page=1 HTTP/1.1" 404
[AdminApi] DioException: 404 - Not Found: /api/admin/events/
```

## Nguyên nhân
Backend **CHƯA CÓ** endpoint `/api/admin/events/`

## Phân tích

### Frontend: ✅ Hoàn chỉnh
- UI đã implement đầy đủ tại `lib/features/admin_dashboard/presentation/screens/admin_event_management_screen.dart`
- API client đã sẵn sàng tại `lib/features/admin/data/api/admin_api.dart`
- Gọi endpoint: `GET /api/admin/events/` với các query params: `page`, `status`, `search`, etc.

### Backend: ❌ Thiếu endpoint
**Hiện tại chỉ có:**
```python
# event_connect_backend/event_connect_backend/urls.py
path('api/event_management/', include('event_management.urls'))
```

Tạo ra:
- `/api/event_management/events/` - User API ✅
- `/api/admin/events/` - **KHÔNG CÓ** ❌

**Cần phải có:**
- `/api/admin/events/` - List all events for System Admin
- `/api/admin/events/{id}/` - Get event detail
- `/api/admin/events/{id}/approve/` - Approve pending event
- `/api/admin/events/{id}/reject/` - Reject pending event
- `/api/admin/events/{id}/cancel/` - Cancel approved event
- `/api/admin/events/statistics/` - Get event statistics

## Giải pháp

### 📄 Đọc document đầy đủ:
**File:** `BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md`

Document này chứa:
- ✅ Tất cả 6 API endpoints cần implement
- ✅ Request/Response format chi tiết (JSON examples)
- ✅ Business logic và validation rules
- ✅ Sample Python/Django code (ViewSet pattern)
- ✅ Database schema updates needed
- ✅ Testing guidelines và checklist
- ✅ Notification requirements (critical!)

### 🚀 Quick Implementation Steps:

1. **Tạo Admin ViewSet:**
   ```bash
   cd event_connect_backend/event_management
   # Tạo hoặc edit views.py
   ```

2. **Copy code từ document:**
   - `AdminEventManagementViewSet` class
   - Implement 4 actions: `approve()`, `reject()`, `cancel()`, `statistics()`

3. **Register URLs:**
   ```python
   # event_management/urls.py
   admin_router = DefaultRouter()
   admin_router.register(r'admin/events', AdminEventManagementViewSet)
   ```

4. **Add database fields:**
   - `approved_at`, `approved_by`
   - `rejection_reason`, `rejected_at`, `rejected_by`
   - `cancellation_reason`, `cancelled_at`, `cancelled_by`

5. **Test:**
   ```bash
   python manage.py runserver
   curl http://localhost:8000/api/admin/events/
   # Should return 401 (auth required) instead of 404
   ```

## Priority

**CRITICAL - P0:**
1. `GET /api/admin/events/` - List events (cần ngay để hiển thị UI)

**HIGH - P1:**
2. `POST /api/admin/events/{id}/approve/` - Approve workflow
3. `POST /api/admin/events/{id}/reject/` - Reject workflow (với reason)

**MEDIUM - P2:**
4. `GET /api/admin/events/{id}/` - Event detail
5. `POST /api/admin/events/{id}/cancel/` - Cancel event
6. `GET /api/admin/events/statistics/` - Statistics

## Critical Requirements

⚠️ **QUAN TRỌNG:**
1. **Reject event:** Phải bắt buộc nhập `reason` → gửi cho CLB biết lý do
2. **Cancel event:** Phải bắt buộc nhập `reason` + gửi thông báo cho **TẤT CẢ** participants
3. **Status flow:** One-way only:
   - `pending` → `approved` ✅
   - `pending` → `rejected` ✅
   - `approved` → `cancelled` ✅
   - Không cho chuyển ngược lại ❌

## Testing Checklist

- [ ] GET `/api/admin/events/` returns 200 (not 404)
- [ ] GET `/api/admin/events/?status=pending` filters correctly
- [ ] POST `/api/admin/events/1/approve/` changes status to approved
- [ ] POST `/api/admin/events/1/reject/` requires `reason` field
- [ ] POST `/api/admin/events/1/cancel/` sends notifications to all participants
- [ ] Cannot approve already approved/rejected event
- [ ] Cannot reject already approved/rejected event
- [ ] Cannot cancel non-approved event
- [ ] Only System Admin can access these endpoints

## Files to Read

1. **`BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md`** - Complete specification (777 lines)
2. **`ADMIN_EVENT_MANAGEMENT_SUMMARY.md`** - High-level overview
3. **`event_connect_backend/event_management/models.py`** - Event model hiện tại
4. **`event_connect_backend/event_management/views.py`** - Existing EventViewSet (tham khảo)

## Related Issues

- User report: "Quản lý duyệt sự kiện bị lỗi" ✅ IDENTIFIED
- Frontend: 100% complete, waiting for backend
- Backend: 0% complete for admin endpoints

---

**Created:** 2025-11-19
**Reporter:** Frontend Team
**Assignee:** Backend Team
**Severity:** CRITICAL - Blocking feature
**ETA Requested:** ASAP (Frontend ready to test immediately after backend implements)
