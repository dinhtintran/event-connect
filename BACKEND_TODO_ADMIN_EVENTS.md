# ⚠️ BACKEND TODO: Admin Event Management API

## 🔴 Problem
```
Frontend: GET /api/admin/events/
Backend:  404 Not Found ❌
```

## ✅ Solution: Implement 6 API Endpoints

### Priority 1: GET List (CRITICAL)
```python
GET /api/admin/events/
→ Return paginated list of all events (with filters: status, search, etc.)
```

### Priority 2: Approval Workflow (HIGH)
```python
POST /api/admin/events/{id}/approve/
→ Change status to "approved", send notification to CLB

POST /api/admin/events/{id}/reject/
→ Change status to "rejected", require reason, send notification to CLB
```

### Priority 3: Detail & Cancel (MEDIUM)
```python
GET  /api/admin/events/{id}/
→ Return single event detail

POST /api/admin/events/{id}/cancel/
→ Change status to "cancelled", require reason, notify ALL participants

GET  /api/admin/events/statistics/
→ Return event counts by status
```

---

## 📋 Quick Implementation (3 Steps)

### 1. Update Event Model
Add tracking fields:
```python
# event_management/models.py
class Event(models.Model):
    # ... existing ...
    
    # NEW fields:
    approved_at = models.DateTimeField(null=True)
    approved_by = models.ForeignKey(User, related_name='approved_events', ...)
    rejection_reason = models.TextField(blank=True)
    rejected_at = models.DateTimeField(null=True)
    rejected_by = models.ForeignKey(User, related_name='rejected_events', ...)
    cancellation_reason = models.TextField(blank=True)
    cancelled_at = models.DateTimeField(null=True)
    cancelled_by = models.ForeignKey(User, related_name='cancelled_events', ...)
```

```bash
python manage.py makemigrations
python manage.py migrate
```

### 2. Create ViewSet
```python
# event_management/admin_views.py (NEW FILE)
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone

class AdminEventManagementViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    permission_classes = [IsSystemAdmin]
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        event = self.get_object()
        if event.status != 'pending':
            return Response({'error': 'Event not pending'}, status=400)
        
        event.status = 'approved'
        event.approved_at = timezone.now()
        event.approved_by = request.user
        event.save()
        
        # TODO: Send notification to CLB
        
        return Response({
            'success': True,
            'message': 'Event approved',
            'event': EventSerializer(event).data
        })
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        event = self.get_object()
        reason = request.data.get('reason')
        
        if not reason:
            return Response({'error': 'Reason required'}, status=400)
        if event.status != 'pending':
            return Response({'error': 'Event not pending'}, status=400)
        
        event.status = 'rejected'
        event.rejection_reason = reason
        event.rejected_at = timezone.now()
        event.rejected_by = request.user
        event.save()
        
        # TODO: Send notification with reason to CLB
        
        return Response({
            'success': True,
            'message': 'Event rejected',
            'event': EventSerializer(event).data
        })
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        event = self.get_object()
        reason = request.data.get('reason')
        
        if not reason:
            return Response({'error': 'Reason required'}, status=400)
        if event.status != 'approved':
            return Response({'error': 'Can only cancel approved events'}, status=400)
        
        event.status = 'cancelled'
        event.cancellation_reason = reason
        event.cancelled_at = timezone.now()
        event.cancelled_by = request.user
        event.save()
        
        # TODO: Send notification to ALL participants
        # TODO: Cancel all registrations
        
        return Response({
            'success': True,
            'message': 'Event cancelled',
            'event': EventSerializer(event).data
        })
    
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        return Response({
            'total': Event.objects.count(),
            'pending': Event.objects.filter(status='pending').count(),
            'approved': Event.objects.filter(status='approved').count(),
            'rejected': Event.objects.filter(status='rejected').count(),
            'cancelled': Event.objects.filter(status='cancelled').count(),
        })
```

### 3. Register URLs
```python
# event_management/urls.py
from .admin_views import AdminEventManagementViewSet

admin_router = DefaultRouter()
admin_router.register(r'admin/events', AdminEventManagementViewSet, basename='admin-events')

urlpatterns = [
    path('', include(router.urls)),
    path('', include(admin_router.urls)),  # ADD THIS
]
```

---

## 🧪 Test
```bash
python manage.py runserver

# Should return 401 (not 404):
curl http://localhost:8000/api/admin/events/

# With admin token should return 200:
curl -H "Authorization: Bearer <token>" http://localhost:8000/api/admin/events/
```

---

## 📖 Full Documentation
- **BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md** - Complete specification (777 lines)
- **ADMIN_EVENT_MANAGEMENT_ARCHITECTURE.md** - Visual guide
- **BUG_ADMIN_EVENT_MANAGEMENT_404.md** - Bug report

---

## ⚠️ Critical Notes
1. **Reject:** MUST require `reason` → sent to CLB
2. **Cancel:** MUST require `reason` → sent to ALL participants
3. **Status flow:** One-way only (pending→approved/rejected, approved→cancelled)
4. **Permission:** Only System Admin can access

---

**Created:** 2025-11-19
**Status:** 🔴 URGENT - Frontend waiting
**ETA:** 4-6 hours
