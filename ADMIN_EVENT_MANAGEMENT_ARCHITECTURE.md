# Admin Event Management - API Architecture

## 📊 Current vs Required Architecture

### ❌ Current (Causing 404)
```
Frontend Request:
GET /api/admin/events/
    ↓
Django URLs:
/api/event_management/events/  ← User API only
    ↓
404 NOT FOUND ❌
```

### ✅ Required Architecture
```
Frontend Request:
GET /api/admin/events/
    ↓
Django URLs:
/api/admin/events/  ← NEW Admin API
    ↓
AdminEventManagementViewSet
    ↓
Permission: IsSystemAdmin
    ↓
200 OK with event list
```

---

## 🏗️ Implementation Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     FRONTEND (READY)                     │
├─────────────────────────────────────────────────────────┤
│  admin_event_management_screen.dart                      │
│  ├─ 4 Tabs: All / Pending / Approved / Rejected        │
│  ├─ Event Cards with Statistics                         │
│  ├─ Approve/Reject/Cancel Buttons                       │
│  └─ Event Detail View                                   │
│                                                          │
│  admin_api.dart                                          │
│  ├─ getAllEvents(page, status, search)                  │
│  ├─ approveEvent(id)                                    │
│  ├─ rejectEvent(id, reason)                             │
│  └─ cancelEvent(id, reason) [TODO]                      │
└─────────────────────────────────────────────────────────┘
                        ↓ HTTP Requests
                    (Bearer Token)
┌─────────────────────────────────────────────────────────┐
│                  BACKEND (MISSING!)                      │
├─────────────────────────────────────────────────────────┤
│  📁 event_management/admin_views.py (NEW FILE)          │
│                                                          │
│  class AdminEventManagementViewSet(viewsets.ModelViewSet)│
│                                                          │
│  Endpoints:                                              │
│  ┌────────────────────────────────────────────────────┐│
│  │ GET    /api/admin/events/                          ││
│  │        → List all events (with filters)            ││
│  │        → Returns: paginated event list             ││
│  │                                                     ││
│  │ GET    /api/admin/events/{id}/                     ││
│  │        → Get event detail                          ││
│  │        → Returns: single event with full info      ││
│  │                                                     ││
│  │ POST   /api/admin/events/{id}/approve/             ││
│  │        → Approve pending event                     ││
│  │        → Changes: status → "approved"              ││
│  │        → Sends: notification to CLB                ││
│  │                                                     ││
│  │ POST   /api/admin/events/{id}/reject/              ││
│  │        → Reject pending event                      ││
│  │        → Requires: reason (mandatory)              ││
│  │        → Changes: status → "rejected"              ││
│  │        → Sends: notification + reason to CLB       ││
│  │                                                     ││
│  │ POST   /api/admin/events/{id}/cancel/              ││
│  │        → Cancel approved event                     ││
│  │        → Requires: reason (mandatory)              ││
│  │        → Changes: status → "cancelled"             ││
│  │        → Sends: notification to ALL participants   ││
│  │        → Cancels: all registrations                ││
│  │                                                     ││
│  │ GET    /api/admin/events/statistics/               ││
│  │        → Get event statistics                      ││
│  │        → Returns: counts by status                 ││
│  └────────────────────────────────────────────────────┘│
│                                                          │
│  Permission: IsSystemAdmin (required)                    │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│                     DATABASE                             │
├─────────────────────────────────────────────────────────┤
│  Event Model (Need to Add):                              │
│  ├─ status (existing)                                   │
│  ├─ approved_at, approved_by (NEW)                      │
│  ├─ rejection_reason, rejected_at, rejected_by (NEW)    │
│  └─ cancellation_reason, cancelled_at, cancelled_by (NEW)│
│                                                          │
│  Notification Model (existing - use for alerts)         │
│  EventRegistration Model (existing - cancel on event cancel)│
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Event Status Flow

```
┌─────────────────────────────────────────────────────────┐
│                    EVENT LIFECYCLE                       │
└─────────────────────────────────────────────────────────┘

    CLB creates event
           ↓
    ┌─────────────┐
    │   PENDING   │ ← Default status when created
    └─────────────┘
         ↓    ↓
         ↓    └────────────────┐
         ↓                     ↓
 [Admin Approve]         [Admin Reject]
         ↓                     ↓
    ┌─────────────┐      ┌─────────────┐
    │  APPROVED   │      │  REJECTED   │
    └─────────────┘      └─────────────┘
         ↓                     ↓
  [Visible to             [Hidden, reason
   students]               sent to CLB]
         ↓
  [Students register,
   check-in, attend]
         ↓
  [Admin Cancel] (optional)
         ↓
    ┌─────────────┐
    │  CANCELLED  │ ← Notifications to ALL participants
    └─────────────┘

Status Transitions:
✅ pending → approved
✅ pending → rejected
✅ approved → cancelled
❌ Cannot reverse (approved/rejected → pending)
❌ Cannot change after cancelled
```

---

## 📋 Implementation Checklist

### Step 1: Database Migration
```bash
cd event_connect_backend
```

Add to `event_management/models.py`:
```python
class Event(models.Model):
    # ... existing fields ...
    
    # NEW: Approval tracking
    approved_at = models.DateTimeField(null=True, blank=True)
    approved_by = models.ForeignKey(User, related_name='approved_events', ...)
    
    # NEW: Rejection tracking
    rejection_reason = models.TextField(blank=True, null=True)
    rejected_at = models.DateTimeField(null=True, blank=True)
    rejected_by = models.ForeignKey(User, related_name='rejected_events', ...)
    
    # NEW: Cancellation tracking
    cancellation_reason = models.TextField(blank=True, null=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancelled_by = models.ForeignKey(User, related_name='cancelled_events', ...)
```

```bash
python manage.py makemigrations
python manage.py migrate
```

### Step 2: Create Admin ViewSet
Create `event_management/admin_views.py`:
```python
from rest_framework import viewsets
from rest_framework.decorators import action
from .models import Event
from .serializers import EventSerializer
from .permissions import IsSystemAdmin

class AdminEventManagementViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    permission_classes = [IsSystemAdmin]
    
    # Copy implementation from BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md
    # Sections: approve(), reject(), cancel(), statistics()
```

### Step 3: Register URLs
Update `event_management/urls.py`:
```python
from .admin_views import AdminEventManagementViewSet

admin_router = DefaultRouter()
admin_router.register(r'admin/events', AdminEventManagementViewSet, basename='admin-events')

urlpatterns = [
    path('', include(router.urls)),  # Existing
    path('', include(admin_router.urls)),  # NEW
]
```

### Step 4: Verify Permission
Check `event_management/permissions.py` has:
```python
class IsSystemAdmin(BasePermission):
    def has_permission(self, request, view):
        return (
            request.user and 
            request.user.is_authenticated and 
            request.user.role == 'system_admin'
        )
```

### Step 5: Test
```bash
python manage.py runserver

# Test 1: Should return 401 (not 404)
curl http://localhost:8000/api/admin/events/

# Test 2: With admin token
curl -H "Authorization: Bearer <admin_token>" \
     http://localhost:8000/api/admin/events/

# Should return 200 with event list
```

---

## 🎯 Success Criteria

✅ Frontend loads without 404 error
✅ Event list displays in UI
✅ Can approve pending events
✅ Can reject with reason
✅ Can cancel approved events
✅ Notifications sent correctly
✅ Only System Admin can access

---

## 📚 Reference Documents

1. **BACKEND_TASKS_ADMIN_EVENT_MANAGEMENT.md** (777 lines)
   - Complete API specification
   - Sample code for all endpoints
   - Database schema
   - Testing guidelines

2. **BUG_ADMIN_EVENT_MANAGEMENT_404.md** (This file context)
   - Bug analysis
   - Quick implementation steps

3. **ADMIN_EVENT_MANAGEMENT_SUMMARY.md**
   - High-level overview
   - UI screenshots reference
   - Frontend-Backend communication flow

---

**Visual Guide Created:** 2025-11-19
**Purpose:** Help backend team understand architecture quickly
**Implementation Time Estimate:** 4-6 hours (with document reference)
