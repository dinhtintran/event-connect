# Backend Tasks - Admin Event Management API

## � CRITICAL: Endpoint `/api/admin/events/` đang trả về 404!

**Triệu chứng:**
```bash
GET /api/admin/events/?page=1 HTTP/1.1" 404
[AdminApi] DioException: 404 - Not Found
```

**Nguyên nhân:** Backend chưa implement endpoint này.

**Frontend:** ✅ Đã sẵn sàng 100% - UI hoàn chỉnh với đầy đủ chức năng quản lý sự kiện.

**Backend:** ❌ Cần implement các API endpoints bên dưới NGAY.

---

## �📋 Overview
System Admin cần quản lý TẤT CẢ sự kiện của tất cả CLB trong hệ thống. Backend cần implement các API endpoints để hỗ trợ quy trình phê duyệt và giám sát sự kiện.

---

## 🎯 Quy trình quản lý sự kiện

### Luồng sự kiện trong hệ thống:

```
1. CLB tạo sự kiện → Status: "pending"
2. System Admin phê duyệt/từ chối
   ├─ Phê duyệt → Status: "approved" → Hiển thị công khai
   └─ Từ chối → Status: "rejected" → Gửi lý do cho CLB
3. Sự kiện đang diễn ra → Sinh viên đăng ký & check-in
4. (Optional) Admin hủy sự kiện → Status: "cancelled"
```

---

## ❌ APIs CẦN IMPLEMENT (ĐANG THIẾU!)

### 1. Get All Events (với filter) - **PRIORITY 1**
```
GET /api/admin/events/
```
**Query params:**
- `status` (optional): Filter by status (pending, approved, rejected, cancelled, all)
- `club_id` (optional): Filter by club
- `search` (optional): Search by title
- `start_date` (optional): Filter events after date
- `end_date` (optional): Filter events before date
- `page` (optional): Page number
- `page_size` (optional): Items per page

**Response:**
```json
{
  "count": 50,
  "results": [
    {
      "id": "1",
      "title": "Workshop Python",
      "club_name": "CLB Lập trình",
      "club_id": "5",
      "location": "Phòng A101",
      "location_detail": "Tòa nhà A, tầng 1",
      "start_at": "2024-02-15T14:00:00Z",
      "end_at": "2024-02-15T17:00:00Z",
      "capacity": 50,
      "status": "pending",
      "registration_count": 0,
      "checked_in_count": 0,
      "attended_count": 0,
      "total_participants": 0,
      "description": "Workshop về Python cơ bản...",
      "poster_url": "https://...",
      "created_at": "2024-02-10T10:00:00Z",
      "updated_at": "2024-02-10T10:00:00Z",
      "created_by": "club_admin_123"
    }
  ]
}
```

**Status:** ❌ CHƯA CÓ - Đang trả về 404!

**Location đề xuất:** `event_connect_backend/events/views.py` hoặc `events/admin_views.py`

---

## ❌ APIs cần implement (Priority 2-6)

### 1. Get Event Detail (Admin View)
```
GET /api/admin/events/{id}/
```

**Response:**
```json
{
  "id": "1",
  "title": "Workshop Python",
  "club_name": "CLB Lập trình",
  "club_id": "5",
  "location": "Phòng A101",
  "location_detail": "Tòa nhà A, tầng 1",
  "start_at": "2024-02-15T14:00:00Z",
  "end_at": "2024-02-15T17:00:00Z",
  "capacity": 50,
  "status": "pending",
  
  // Participant Statistics
  "registration_count": 25,
  "checked_in_count": 20,
  "attended_count": 18,
  "total_participants": 25,
  "cancelled_count": 5,
  
  // Detailed Info
  "description": "Workshop về Python cơ bản cho sinh viên mới...",
  "poster_url": "https://example.com/poster.jpg",
  "risk_level": "low",
  "category": "workshop",
  
  // Admin Info
  "created_by": {
    "id": "123",
    "username": "admin_clb",
    "full_name": "Nguyen Van A",
    "role": "club_admin"
  },
  "created_at": "2024-02-10T10:00:00Z",
  "updated_at": "2024-02-10T10:00:00Z",
  
  // Approval History (nếu có)
  "approved_at": null,
  "approved_by": null,
  "rejection_reason": null,
  "rejected_at": null,
  "rejected_by": null
}
```

**Permission:** System Admin only

---

### 2. Approve Event
```
POST /api/admin/events/{id}/approve/
```

**Request body:**
```json
{
  "note": "Sự kiện được phê duyệt" // Optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "Event approved successfully",
  "event": {
    "id": "1",
    "title": "Workshop Python",
    "status": "approved",
    "approved_at": "2024-02-11T09:00:00Z",
    "approved_by": "admin_123"
  }
}
```

**Permission:** System Admin only

**Logic:**
- Check event status = "pending"
- Set `status = "approved"`
- Record `approved_at = now()`
- Record `approved_by = request.user.id`
- Send notification to CLB (event approved)
- Return 400 nếu event không ở trạng thái pending

**Side Effects:**
- Sự kiện hiển thị công khai cho sinh viên
- CLB nhận thông báo phê duyệt
- Activity log được tạo

---

### 3. Reject Event
```
POST /api/admin/events/{id}/reject/
```

**Request body:**
```json
{
  "reason": "Nội dung sự kiện không phù hợp với quy định nhà trường" // Required
}
```

**Response:**
```json
{
  "success": true,
  "message": "Event rejected successfully",
  "event": {
    "id": "1",
    "title": "Workshop Python",
    "status": "rejected",
    "rejection_reason": "Nội dung sự kiện không phù hợp...",
    "rejected_at": "2024-02-11T09:00:00Z",
    "rejected_by": "admin_123"
  }
}
```

**Permission:** System Admin only

**Validation:**
- `reason` is required và không được rỗng
- Event phải ở trạng thái "pending"

**Logic:**
- Set `status = "rejected"`
- Save `rejection_reason`
- Record `rejected_at = now()`
- Record `rejected_by = request.user.id`
- Send notification to CLB với lý do từ chối
- Return 400 nếu không có reason hoặc event không pending

---

### 4. Cancel Event (Hủy sự kiện đã duyệt)
```
POST /api/admin/events/{id}/cancel/
```

**Request body:**
```json
{
  "reason": "Sự kiện bị hủy do thiên tai" // Required
}
```

**Response:**
```json
{
  "success": true,
  "message": "Event cancelled successfully",
  "event": {
    "id": "1",
    "title": "Workshop Python",
    "status": "cancelled",
    "cancellation_reason": "Sự kiện bị hủy do thiên tai",
    "cancelled_at": "2024-02-14T08:00:00Z",
    "cancelled_by": "admin_123"
  },
  "notifications_sent": 25 // Số lượng thông báo đã gửi
}
```

**Permission:** System Admin only

**Validation:**
- `reason` is required
- Event phải đang ở trạng thái "approved"

**Logic:**
- Set `status = "cancelled"`
- Save `cancellation_reason`
- Record `cancelled_at = now()`
- Record `cancelled_by = request.user.id`
- **IMPORTANT:** Send notifications to ALL registered participants
- Cancel all active registrations
- Update participant counts
- Activity log

**⚠️ Critical:**
- Phải gửi thông báo đến TẤT CẢ người đã đăng ký
- Không xóa data (soft cancel)
- Giữ lịch sử để tracking

---

### 5. Get Event Statistics (Dashboard)
```
GET /api/admin/events/statistics/
```

**Query params:**
- `period` (optional): day, week, month, year (default: month)
- `start_date` (optional): Custom start date
- `end_date` (optional): Custom end date

**Response:**
```json
{
  "total_events": 150,
  "pending_events": 5,
  "approved_events": 120,
  "rejected_events": 15,
  "cancelled_events": 10,
  "total_participants": 3500,
  "events_by_club": [
    {
      "club_id": "1",
      "club_name": "CLB Lập trình",
      "event_count": 25,
      "total_participants": 800
    }
  ],
  "events_by_month": [
    {
      "month": "2024-02",
      "total": 12,
      "pending": 2,
      "approved": 8,
      "rejected": 2
    }
  ]
}
```

**Permission:** System Admin only

**Use case:** Dashboard statistics

---

## 🔐 Permissions

Tất cả endpoints yêu cầu:
```python
@permission_classes([IsSystemAdmin])
```

**IsSystemAdmin:**
```python
class IsSystemAdmin(BasePermission):
    def has_permission(self, request, view):
        return (
            request.user and 
            request.user.is_authenticated and 
            request.user.role == 'system_admin'
        )
```

---

## 📁 Suggested Implementation

### Location
`event_connect_backend/events/admin_views.py` (hoặc trong existing views)

### Approach: ViewSet với custom actions

```python
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from django.db.models import Count, Q

class AdminEventManagementViewSet(viewsets.ModelViewSet):
    """
    System Admin Event Management
    Quản lý tất cả sự kiện của tất cả CLB
    """
    permission_classes = [IsSystemAdmin]
    serializer_class = EventDetailSerializer
    
    def get_queryset(self):
        queryset = Event.objects.all().select_related('club', 'created_by')
        
        # Filters
        status_filter = self.request.query_params.get('status')
        club_id = self.request.query_params.get('club_id')
        search = self.request.query_params.get('search')
        
        if status_filter and status_filter != 'all':
            queryset = queryset.filter(status=status_filter)
        
        if club_id:
            queryset = queryset.filter(club_id=club_id)
        
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search)
            )
        
        return queryset.order_by('-created_at')
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Phê duyệt sự kiện"""
        event = self.get_object()
        
        if event.status != 'pending':
            return Response(
                {'error': 'Only pending events can be approved'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        event.status = 'approved'
        event.approved_at = timezone.now()
        event.approved_by = request.user
        event.save()
        
        # Send notification to club
        self._send_approval_notification(event)
        
        # Create activity log
        self._create_activity_log(
            action='approve_event',
            event=event,
            user=request.user
        )
        
        return Response({
            'success': True,
            'message': 'Event approved successfully',
            'event': EventSerializer(event).data
        })
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Từ chối sự kiện"""
        event = self.get_object()
        reason = request.data.get('reason', '').strip()
        
        if not reason:
            return Response(
                {'error': 'Rejection reason is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if event.status != 'pending':
            return Response(
                {'error': 'Only pending events can be rejected'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        event.status = 'rejected'
        event.rejection_reason = reason
        event.rejected_at = timezone.now()
        event.rejected_by = request.user
        event.save()
        
        # Send notification to club with reason
        self._send_rejection_notification(event, reason)
        
        # Create activity log
        self._create_activity_log(
            action='reject_event',
            event=event,
            user=request.user,
            note=reason
        )
        
        return Response({
            'success': True,
            'message': 'Event rejected successfully',
            'event': EventSerializer(event).data
        })
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Hủy sự kiện (chỉ admin system)"""
        event = self.get_object()
        reason = request.data.get('reason', '').strip()
        
        if not reason:
            return Response(
                {'error': 'Cancellation reason is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if event.status != 'approved':
            return Response(
                {'error': 'Only approved events can be cancelled'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        event.status = 'cancelled'
        event.cancellation_reason = reason
        event.cancelled_at = timezone.now()
        event.cancelled_by = request.user
        event.save()
        
        # Cancel all registrations
        cancelled_count = self._cancel_all_registrations(event)
        
        # Send notifications to ALL participants
        notifications_sent = self._send_cancellation_notifications(event, reason)
        
        # Create activity log
        self._create_activity_log(
            action='cancel_event',
            event=event,
            user=request.user,
            note=reason
        )
        
        return Response({
            'success': True,
            'message': 'Event cancelled successfully',
            'event': EventSerializer(event).data,
            'notifications_sent': notifications_sent,
            'registrations_cancelled': cancelled_count
        })
    
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Lấy thống kê sự kiện"""
        # Implementation của statistics endpoint
        stats = {
            'total_events': Event.objects.count(),
            'pending_events': Event.objects.filter(status='pending').count(),
            'approved_events': Event.objects.filter(status='approved').count(),
            'rejected_events': Event.objects.filter(status='rejected').count(),
            'cancelled_events': Event.objects.filter(status='cancelled').count(),
            # ... more stats
        }
        return Response(stats)
    
    def _send_approval_notification(self, event):
        """Gửi thông báo phê duyệt đến CLB"""
        # Implementation
        pass
    
    def _send_rejection_notification(self, event, reason):
        """Gửi thông báo từ chối với lý do"""
        # Implementation
        pass
    
    def _send_cancellation_notifications(self, event, reason):
        """Gửi thông báo hủy đến tất cả participants"""
        # Implementation
        return notification_count
    
    def _cancel_all_registrations(self, event):
        """Hủy tất cả registrations của event"""
        # Implementation
        return cancelled_count
    
    def _create_activity_log(self, action, event, user, note=None):
        """Tạo activity log"""
        # Implementation
        pass
```

### URL Configuration
```python
# events/urls.py
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(
    r'admin/events', 
    AdminEventManagementViewSet, 
    basename='admin-events'
)

urlpatterns = [
    path('', include(router.urls)),
]
```

**Result URLs:**
```
GET    /api/admin/events/                    # List all events (with filters)
GET    /api/admin/events/{id}/               # Get event detail
POST   /api/admin/events/{id}/approve/       # Approve event
POST   /api/admin/events/{id}/reject/        # Reject event
POST   /api/admin/events/{id}/cancel/        # Cancel event
GET    /api/admin/events/statistics/         # Get statistics
```

---

## 📊 Database Schema Updates

### Event Model (cần thêm fields)

```python
class Event(models.Model):
    # ... existing fields ...
    
    # Approval fields
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('approved', 'Approved'),
            ('rejected', 'Rejected'),
            ('cancelled', 'Cancelled'),
        ],
        default='pending'
    )
    
    # Approval tracking
    approved_at = models.DateTimeField(null=True, blank=True)
    approved_by = models.ForeignKey(
        User, 
        related_name='approved_events',
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    
    # Rejection tracking
    rejection_reason = models.TextField(blank=True, null=True)
    rejected_at = models.DateTimeField(null=True, blank=True)
    rejected_by = models.ForeignKey(
        User,
        related_name='rejected_events',
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    
    # Cancellation tracking
    cancellation_reason = models.TextField(blank=True, null=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancelled_by = models.ForeignKey(
        User,
        related_name='cancelled_events',
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
```

**Migration needed:**
```bash
python manage.py makemigrations
python manage.py migrate
```

---

## 🧪 Testing

### Test Cases

**1. Approve Event:**
```bash
curl -X POST \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"note": "Approved"}' \
  http://localhost:8000/api/admin/events/1/approve/
```

**2. Reject Event:**
```bash
curl -X POST \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Nội dung không phù hợp"}' \
  http://localhost:8000/api/admin/events/1/reject/
```

**3. Cancel Event:**
```bash
curl -X POST \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Thiên tai"}' \
  http://localhost:8000/api/admin/events/1/cancel/
```

**4. Get Statistics:**
```bash
curl -H "Authorization: Bearer <admin_token>" \
  http://localhost:8000/api/admin/events/statistics/
```

---

## ✅ Checklist

Backend team cần hoàn thành:

### Database & Models
- [ ] Thêm approval/rejection/cancellation fields vào Event model
- [ ] Tạo migration và chạy migrate
- [ ] Update Event serializer với các fields mới

### API Implementation
- [ ] Tạo `AdminEventManagementViewSet`
- [ ] Implement `approve()` action
- [ ] Implement `reject()` action
- [ ] Implement `cancel()` action
- [ ] Implement `statistics()` action
- [ ] Register router trong urls.py

### Permissions
- [ ] Verify `IsSystemAdmin` permission class
- [ ] Test permissions cho tất cả endpoints

### Notifications
- [ ] Implement approval notification (gửi cho CLB)
- [ ] Implement rejection notification (với lý do)
- [ ] Implement cancellation notifications (gửi cho TẤT CẢ participants)

### Business Logic
- [ ] Handle event status transitions
- [ ] Validate status changes (pending → approved/rejected, approved → cancelled)
- [ ] Cancel registrations when event cancelled
- [ ] Activity logging for all admin actions

### Testing
- [ ] Test approve endpoint
- [ ] Test reject endpoint (với và không có reason)
- [ ] Test cancel endpoint
- [ ] Test cannot approve/reject already processed events
- [ ] Test cannot cancel non-approved events
- [ ] Test statistics endpoint
- [ ] Test permissions (non-admin cannot access)

---

## 📝 Important Notes

1. **Notification System Critical:**
   - Khi hủy sự kiện, PHẢI gửi thông báo đến tất cả người đã đăng ký
   - Thông báo phải bao gồm lý do hủy

2. **Status Flow:**
   ```
   pending → approved ✅
   pending → rejected ✅
   approved → cancelled ✅
   
   Không được:
   approved → rejected ❌
   rejected → approved ❌
   cancelled → anything ❌
   ```

3. **Data Integrity:**
   - Không xóa events (soft delete/cancel)
   - Giữ tất cả history (approved_by, rejected_by, etc.)
   - Activity logs cho audit trail

4. **Frontend Ready:**
   - Frontend đã implement đầy đủ UI
   - Chỉ cần backend APIs hoàn thành là có thể test ngay

---

## 🔗 Related Files

**Frontend:**
- `lib/features/admin_dashboard/presentation/screens/admin_event_management_screen.dart` - UI hoàn chỉnh
- `lib/features/admin/data/api/admin_api.dart` - API client đã sẵn sàng

**Backend (hiện tại):**
- `event_connect_backend/event_management/views.py` - EventViewSet (user API)
- `event_connect_backend/event_management/urls.py` - Routes hiện tại (không có admin)
- `event_connect_backend/event_connect_backend/urls.py` - Main URLs

---

## 🚀 Quick Start cho Backend Team

### Bước 1: Tạo Admin ViewSet
```bash
cd event_connect_backend/event_management
# Tạo file mới hoặc thêm vào views.py:
touch admin_views.py
```

### Bước 2: Implement API theo specification ở trên
- Copy/paste `AdminEventManagementViewSet` từ section **Implementation**
- Verify `IsSystemAdmin` permission
- Implement notification functions

### Bước 3: Register URLs
```python
# event_management/urls.py
from .admin_views import AdminEventManagementViewSet

admin_router = DefaultRouter()
admin_router.register(r'admin/events', AdminEventManagementViewSet, basename='admin-events')

urlpatterns = [
    # Existing routes
    path('', include(router.urls)),
    # Admin routes
    path('', include(admin_router.urls)),
]
```

### Bước 4: Test endpoint
```bash
# Run server
python manage.py runserver

# Test
curl http://localhost:8000/api/admin/events/
# Should return 401 (not authenticated) instead of 404
```

---

## ❓ Thắc mắc?

Contact frontend team nếu cần clarify về:
- Request/response formats
- Frontend behavior
- UI workflows

**Created:** 2025-11-19
**Status:** 🔴 BACKEND CHƯA CÓ ENDPOINT - Đang 404
**Last Updated:** 2025-11-19 (Added 404 error diagnosis)
- `lib/features/admin/data/api/admin_api.dart` - API client (cần update)
- `lib/features/admin/domain/services/admin_service.dart` - Service layer

**Backend:**
- `event_connect_backend/events/models.py` - Event model
- `event_connect_backend/events/views.py` - Event views
- `event_connect_backend/notifications/` - Notification system

---

## 📞 Contact

Nếu có thắc mắc về workflow hoặc cần sync API contract, vui lòng liên hệ Frontend team.

**Created:** 2025-11-19
**Status:** 🔴 Pending Implementation
**Priority:** 🔥 High - Core feature for System Admin
