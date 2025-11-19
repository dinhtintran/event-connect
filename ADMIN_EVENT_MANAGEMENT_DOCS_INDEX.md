# 📚 Admin Event Management - Documentation Index

## 🚨 Current Issue
**Frontend gọi `/api/admin/events/` → Backend trả về 404**

Lỗi này xảy ra vì backend chưa implement endpoint quản lý sự kiện cho System Admin.

---

## 📖 Document Structure

### 🔴 Đọc theo thứ tự này:

#### 1️⃣ **BACKEND_TODO_ADMIN_EVENTS.md** (START HERE!)
- ⏱️ 5 phút đọc
- 🎯 Quick start guide cho backend team
- ✅ 3 bước implementation cơ bản
- 📝 Sample code để copy/paste
- **→ ĐỌC ĐẦU TIÊN để biết phải làm gì**

#### 2️⃣ **BUG_ADMIN_EVENT_MANAGEMENT_404.md**
- ⏱️ 5 phút đọc
- 🐛 Bug report và analysis
- 📊 Priority của các endpoints
- ✅ Testing checklist
- **→ Hiểu rõ vấn đề và cách verify fix**

#### 3️⃣ **ADMIN_EVENT_MANAGEMENT_ARCHITECTURE.md**
- ⏱️ 10 phút đọc
- 🏗️ Visual architecture diagrams
- 🔄 Event status flow charts
- 📋 Step-by-step implementation checklist
- **→ Hiểu toàn bộ kiến trúc và luồng dữ liệu**

#### 4️⃣ **BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md** (REFERENCE)
- ⏱️ 30+ phút đọc
- 📖 Complete API specification (777 lines)
- 🔧 Detailed request/response formats
- 💾 Database schema updates
- 🧪 Comprehensive testing guide
- **→ Document chính thức, đầy đủ nhất**

#### 5️⃣ **ADMIN_EVENT_MANAGEMENT_SUMMARY.md**
- ⏱️ 5 phút đọc
- 📱 Frontend feature overview
- 🎨 UI/UX description
- 🤝 Frontend-Backend communication
- **→ Hiểu frontend đã làm gì**

---

## 🎯 Quick Reference by Role

### 🖥️ Backend Developer (BẠN ĐANG Ở ĐÂY!)
```
1. Read: BACKEND_TODO_ADMIN_EVENTS.md (5 min)
2. Implement: 3 steps (4-6 hours)
3. Reference: BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md when needed
4. Verify: BUG_ADMIN_EVENT_MANAGEMENT_404.md checklist
```

### 📱 Frontend Developer
```
✅ Frontend hoàn chỉnh 100%
- UI: admin_event_management_screen.dart
- API: admin_api.dart
→ Waiting for backend APIs
```

### 👔 Project Manager
```
Status: Backend missing endpoints causing 404
Impact: Admin cannot manage events
Priority: CRITICAL
ETA: 4-6 hours after backend starts
```

---

## 🔍 Find Specific Information

| Cần tìm | Đọc file |
|---------|----------|
| Làm gì để fix 404? | BACKEND_TODO_ADMIN_EVENTS.md |
| API request/response format? | BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md |
| Database schema cần update gì? | BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md, Section "Database Schema" |
| Event status flow như thế nào? | ADMIN_EVENT_MANAGEMENT_ARCHITECTURE.md, Section "Event Status Flow" |
| Sample code implement ViewSet? | BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md, Section "Implementation" |
| Testing checklist? | BUG_ADMIN_EVENT_MANAGEMENT_404.md, Section "Testing Checklist" |
| UI có gì? | ADMIN_EVENT_MANAGEMENT_SUMMARY.md |
| Visual diagrams? | ADMIN_EVENT_MANAGEMENT_ARCHITECTURE.md |

---

## 📊 Implementation Summary

### ✅ Frontend Status (100% Complete)
- [x] Admin Event Management Screen with 4 tabs
- [x] Event cards with statistics display
- [x] Approve/Reject/Cancel workflows with confirmations
- [x] Event detail bottom sheet
- [x] Error handling and empty states
- [x] Pull-to-refresh functionality
- [x] API client ready (admin_api.dart)

### ❌ Backend Status (0% Complete)
- [ ] GET /api/admin/events/ - List events
- [ ] GET /api/admin/events/{id}/ - Event detail
- [ ] POST /api/admin/events/{id}/approve/ - Approve event
- [ ] POST /api/admin/events/{id}/reject/ - Reject event
- [ ] POST /api/admin/events/{id}/cancel/ - Cancel event
- [ ] GET /api/admin/events/statistics/ - Statistics
- [ ] Database fields: approved_at, rejected_at, cancelled_at, etc.
- [ ] Notification system integration

---

## 🚀 Next Steps

### Backend Team (IMMEDIATE):
1. **Read:** BACKEND_TODO_ADMIN_EVENTS.md (5 minutes)
2. **Implement:** 
   - Database migration (30 min)
   - ViewSet with 4 actions (2-3 hours)
   - URL registration (15 min)
   - Test endpoints (1 hour)
3. **Integrate:** Notification system (1-2 hours)
4. **Verify:** Run testing checklist

### Frontend Team (WAITING):
- ✅ Code complete
- 🔄 Ready to test when backend ready
- 📋 Will verify all workflows end-to-end

---

## ⚠️ Critical Requirements (Đừng quên!)

1. **Reject Event:**
   - MUST require `reason` field
   - Send notification with reason to CLB (club admin)

2. **Cancel Event:**
   - MUST require `reason` field
   - Send notification to **ALL registered participants**
   - Cancel all event registrations

3. **Status Flow (One-way only):**
   ```
   pending → approved ✅
   pending → rejected ✅
   approved → cancelled ✅
   
   approved → pending ❌ (không được reverse)
   rejected → approved ❌ (không được reverse)
   ```

4. **Permission:**
   - Only `system_admin` role can access these endpoints
   - Use `IsSystemAdmin` permission class

---

## 📞 Contact

**Issue:** Admin Event Management 404 Error
**Reporter:** Frontend Team
**Date:** 2025-11-19
**Severity:** 🔴 CRITICAL - Blocking feature

Nếu có thắc mắc về:
- API contracts → Liên hệ Frontend team
- Business logic → Đọc BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md
- Technical implementation → Tham khảo existing EventViewSet

---

## 📝 Related Files

**Frontend:**
- `lib/features/admin_dashboard/presentation/screens/admin_event_management_screen.dart`
- `lib/features/admin/data/api/admin_api.dart`
- `lib/features/admin/data/services/admin_service.dart`

**Backend (Need to create):**
- `event_connect_backend/event_management/admin_views.py` (NEW)
- `event_connect_backend/event_management/models.py` (UPDATE)
- `event_connect_backend/event_management/urls.py` (UPDATE)

**Documentation:**
- All 5 MD files in this index

---

## 🏁 Success Criteria

✅ Backend implements 6 endpoints
✅ Frontend loads without 404 error
✅ Admin can view all events with filtering
✅ Admin can approve pending events
✅ Admin can reject with reason (sent to CLB)
✅ Admin can cancel with notifications (sent to participants)
✅ Only System Admin has access
✅ Status transitions work correctly
✅ Notifications sent as specified

---

**Documentation Created:** 2025-11-19
**Last Updated:** 2025-11-19
**Status:** 🔴 BACKEND IMPLEMENTATION REQUIRED
