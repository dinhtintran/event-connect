# 🐛 Backend Bug: Filter participants by status trả về 404

## 📋 Mô tả lỗi

**Endpoint:** `GET /api/events/{id}/participants/`

**Triệu chứng:**
- ✅ `GET /api/events/1/participants/` → 200 OK (không có query params)
- ❌ `GET /api/events/1/participants/?status=registered` → 404 Not Found
- ❌ `GET /api/events/1/participants/?status=attended` → 404 Not Found
- ❌ `GET /api/events/1/participants/?status=cancelled` → 404 Not Found

**Error message:** `"No Event matches the given query."`

---

## 🎯 Nguyên nhân

Backend đang query **Event** thay vì **EventParticipant** khi có query parameter `status`.

### ❌ Backend code có thể đang như thế này:

```python
# views.py (SAI)
class EventParticipantViewSet(viewsets.ReadOnlyModelViewSet):
    def get_queryset(self):
        event_id = self.kwargs['pk']
        status = self.request.query_params.get('status')
        
        # ❌ BUG: Đang filter Event thay vì EventParticipant
        if status:
            return Event.objects.filter(id=event_id, status=status)  # SAI!
        
        return EventParticipant.objects.filter(event_id=event_id)
```

Hoặc:

```python
# Có thể ViewSet đang override get_object() sai
def get_object(self):
    event_id = self.kwargs['pk']
    status = self.request.query_params.get('status')
    
    if status:
        # Trying to get Event with status filter
        return Event.objects.get(id=event_id, status=status)  # ❌ SAI
```

---

## ✅ Cách sửa Backend

### Solution 1: Fix ViewSet get_queryset()

```python
# views.py (ĐÚNG)
from rest_framework import viewsets, permissions
from .models import EventParticipant
from .serializers import EventParticipantSerializer

class EventParticipantViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing event participants
    URL: /api/events/{event_id}/participants/
    """
    serializer_class = EventParticipantSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """
        Filter participants by event_id and optional status
        """
        event_id = self.kwargs.get('pk') or self.kwargs.get('event_pk')
        status = self.request.query_params.get('status')
        
        if not event_id:
            return EventParticipant.objects.none()
        
        # ✅ ĐÚNG: Filter EventParticipant, not Event
        queryset = EventParticipant.objects.filter(event_id=event_id)
        
        # Filter by status if provided
        if status:
            queryset = queryset.filter(status=status)
        
        return queryset.select_related('user', 'event')
```

### Solution 2: Fix URLs routing (nếu dùng nested router)

```python
# urls.py
from rest_framework_nested import routers
from .views import EventViewSet, EventParticipantViewSet

router = routers.DefaultRouter()
router.register(r'events', EventViewSet, basename='event')

# Nested router for participants
events_router = routers.NestedDefaultRouter(router, r'events', lookup='event')
events_router.register(
    r'participants',
    EventParticipantViewSet,
    basename='event-participants'
)

urlpatterns = [
    path('api/', include(router.urls)),
    path('api/', include(events_router.urls)),
]
```

### Solution 3: Fix serializer (nếu cần)

```python
# serializers.py
class EventParticipantSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    event = EventSerializer(read_only=True)
    
    class Meta:
        model = EventParticipant
        fields = [
            'id',
            'user',
            'event',
            'status',  # registered, attended, cancelled
            'registered_at',
            'attended_at',
        ]
        read_only_fields = ['id', 'registered_at', 'attended_at']
```

---

## 🔧 Frontend Workaround (Đã apply)

Trong khi chờ backend fix, frontend đã được update để:

1. **Luôn fetch tất cả participants** (không gửi status param)
2. **Filter ở frontend** bằng JavaScript

```dart
// event_participants_screen.dart
final allParticipants = await _repository.getEventParticipants(
  widget.event.id,
  status: null, // ✅ Always null to avoid 404
);

// Filter on frontend
final filteredParticipants = _selectedStatus == 'all'
    ? allParticipants
    : allParticipants.where((p) => p['status'] == _selectedStatus).toList();
```

**Ưu điểm:**
- ✅ App hoạt động ngay lập tức
- ✅ Filter vẫn work

**Nhược điểm:**
- ❌ Load nhiều data hơn cần thiết (nếu có 1000 participants nhưng chỉ muốn xem 10 attended)
- ❌ Không tối ưu cho performance

---

## 🧪 Testing Backend Fix

### Test Case 1: Get all participants
```bash
curl -X GET "http://127.0.0.1:8000/api/events/1/participants/" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:** 200 OK với list tất cả participants

### Test Case 2: Filter by status=registered
```bash
curl -X GET "http://127.0.0.1:8000/api/events/1/participants/?status=registered" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:** 200 OK với list chỉ participants có status='registered'

### Test Case 3: Filter by status=attended
```bash
curl -X GET "http://127.0.0.1:8000/api/events/1/participants/?status=attended" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:** 200 OK với list chỉ participants có status='attended'

### Test Case 4: Invalid status
```bash
curl -X GET "http://127.0.0.1:8000/api/events/1/participants/?status=invalid" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:** 200 OK với empty list (không có participants với status='invalid')

---

## 📝 Backend Checklist

- [ ] Fix `get_queryset()` để filter `EventParticipant`, không phải `Event`
- [ ] Test với Postman/curl cho tất cả status values
- [ ] Verify không có regression (không có status param vẫn work)
- [ ] Check performance với nhiều participants
- [ ] Update API documentation

---

## 🔄 Khi nào remove Frontend Workaround?

Sau khi backend fix xong:

1. Verify bằng curl/Postman
2. Update `event_participants_screen.dart` để gửi status param lại
3. Test trên app
4. Remove workaround comment

```dart
// AFTER backend fix, restore to:
final status = _selectedStatus == 'all' ? null : _selectedStatus;
final participants = await _repository.getEventParticipants(
  widget.event.id,
  status: status, // ✅ Can use status param now
);
```

---

## 📚 Related Files

- `event_participants_screen.dart` - Frontend đã có workaround
- `BACKEND_REQUIREMENTS.md` - Section 2.2 về ViewSet
- `QUICK_FIX_SUMMARY.md` - Permission fix guide

---

**Priority:** 🟡 MEDIUM - App hoạt động được với workaround, nhưng cần fix để optimize performance

**Impact:** 
- ⚠️ Frontend load nhiều data hơn cần thiết
- ⚠️ Không scale tốt với nhiều participants
- ⚠️ Backend API không consistent

**Estimated Fix Time:** 15-30 phút
