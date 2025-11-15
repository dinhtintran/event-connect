# Backend Implementation Guide: Multiple Participant Counts

## Overview
Hướng dẫn implement nhiều loại count để theo dõi participants qua các giai đoạn của event lifecycle.

---

## Problem Statement

### Current Issue
- `registration_count` hiện tại chỉ đếm participants với `status='registered'`
- Khi participants check-in hoặc attend event, count giảm về 0
- Frontend hiển thị "0/50" mặc dù có người đã tham gia

### Example:
```
Event: AI Workshop
- Ban đầu: 10 người đăng ký → "10/50" ✅
- Trong event: 10 người check-in → "0/50" ❌ (misleading)
- Sau event: 10 người attended → "0/50" ❌ (không thể hiện thành công)
```

---

## Solution: Multiple Count Fields

Add 4 count fields để theo dõi participants ở mọi giai đoạn:

| Field Name | Description | Use Case |
|------------|-------------|----------|
| `registration_count` | Đang đăng ký (chưa check-in) | "Còn X người chờ check-in" |
| `checked_in_count` | Đã check-in (đang trong event) | "X người đã đến" |
| `attended_count` | Đã hoàn thành tham dự | "X người đã tham dự" (lịch sử) |
| `total_participants` | Tổng số người (trừ cancelled) | "Tổng X người tham gia" |

---

## Implementation Steps

### Step 1: Update EventSerializer

**File:** `events/serializers.py` (hoặc tương tự)

```python
from rest_framework import serializers
from django.db.models import Q, Count
from .models import Event, EventParticipant

class EventSerializer(serializers.ModelSerializer):
    """
    Event serializer with multiple participant counts
    """
    # Existing fields
    registration_count = serializers.SerializerMethodField()
    
    # NEW: Additional count fields
    checked_in_count = serializers.SerializerMethodField()
    attended_count = serializers.SerializerMethodField()
    total_participants = serializers.SerializerMethodField()
    
    class Meta:
        model = Event
        fields = [
            'id',
            'title',
            'description',
            'capacity',
            'registration_count',    # Existing
            'checked_in_count',       # NEW
            'attended_count',         # NEW
            'total_participants',     # NEW
            # ... other fields
        ]
    
    def get_registration_count(self, obj):
        """
        Count participants with status='registered'
        These are people who signed up but haven't checked in yet
        """
        return obj.eventparticipant_set.filter(
            status='registered'
        ).count()
    
    def get_checked_in_count(self, obj):
        """
        Count participants with status='checked_in'
        These are people who have arrived at the event
        """
        return obj.eventparticipant_set.filter(
            status='checked_in'
        ).count()
    
    def get_attended_count(self, obj):
        """
        Count participants with status='attended'
        These are people who completed the event
        """
        return obj.eventparticipant_set.filter(
            status='attended'
        ).count()
    
    def get_total_participants(self, obj):
        """
        Count ALL participants except cancelled
        This represents the total number of people involved with the event
        """
        return obj.eventparticipant_set.exclude(
            status='cancelled'
        ).count()
```

---

### Step 2: Optimize with Annotations (Performance Improvement)

For better performance with large datasets, use queryset annotations:

```python
# events/views.py or viewsets.py

from django.db.models import Count, Q
from rest_framework import viewsets
from .models import Event
from .serializers import EventSerializer

class EventViewSet(viewsets.ModelViewSet):
    serializer_class = EventSerializer
    
    def get_queryset(self):
        """
        Optimize queryset with pre-calculated counts
        Reduces N+1 query problem
        """
        queryset = Event.objects.annotate(
            # Count by status
            registered_count=Count(
                'eventparticipant',
                filter=Q(eventparticipant__status='registered')
            ),
            checked_in_count=Count(
                'eventparticipant',
                filter=Q(eventparticipant__status='checked_in')
            ),
            attended_count=Count(
                'eventparticipant',
                filter=Q(eventparticipant__status='attended')
            ),
            total_participants_count=Count(
                'eventparticipant',
                filter=~Q(eventparticipant__status='cancelled')
            ),
        ).select_related('club')  # Optimize club queries too
        
        return queryset
    
    # Optional: Override serializer to use annotated fields
    def get_serializer_class(self):
        return EventSerializerOptimized if self.action == 'list' else EventSerializer


class EventSerializerOptimized(EventSerializer):
    """
    Use annotated counts from queryset for better performance
    """
    def get_registration_count(self, obj):
        # Use annotated field if available
        return getattr(obj, 'registered_count', 
                      super().get_registration_count(obj))
    
    def get_checked_in_count(self, obj):
        return getattr(obj, 'checked_in_count', 
                      super().get_checked_in_count(obj))
    
    def get_attended_count(self, obj):
        return getattr(obj, 'attended_count', 
                      super().get_attended_count(obj))
    
    def get_total_participants(self, obj):
        return getattr(obj, 'total_participants_count', 
                      super().get_total_participants(obj))
```

---

### Step 3: Update API Documentation

**Expected Response Format:**

```json
{
  "id": 3,
  "title": "AI Workshop - Basic",
  "description": "Learn the basics of AI",
  "capacity": 50,
  "registration_count": 0,      // Người đang đăng ký (chưa check-in)
  "checked_in_count": 3,         // Người đã check-in (đang trong event)
  "attended_count": 0,           // Người đã hoàn thành event
  "total_participants": 3,       // Tổng số người (trừ cancelled)
  "poster": "...",
  "start_at": "2025-11-20T10:00:00Z",
  // ... other fields
}
```

---

## Participant Status Lifecycle

Understanding how counts change through event lifecycle:

```
┌─────────────────────────────────────────────────────────────┐
│                   Event Lifecycle                            │
└─────────────────────────────────────────────────────────────┘

Phase 1: BEFORE EVENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User registers → status='registered'

registration_count:  +1  (now 1)
checked_in_count:     0
attended_count:       0
total_participants:  +1  (now 1)

Display: "1/50 người đăng ký"


Phase 2: DURING EVENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User checks in → status='checked_in'

registration_count:  -1  (now 0)
checked_in_count:    +1  (now 1)
attended_count:       0
total_participants:   1  (unchanged)

Display: "1 đã đến / 1 đã đăng ký"


Phase 3: AFTER EVENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mark as attended → status='attended'

registration_count:   0
checked_in_count:    -1  (now 0)
attended_count:      +1  (now 1)
total_participants:   1  (unchanged)

Display: "1 đã tham dự"


Special Case: CANCELLATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User cancels → status='cancelled'

registration_count:  -1  (now 0)
checked_in_count:     0
attended_count:       0
total_participants:  -1  (now 0)

Display: "0/50" (correct - nobody is participating)
```

---

## Testing

### Test Case 1: Empty Event
```python
# Setup
event = Event.objects.create(title="Test Event", capacity=50)

# Expected
assert event.registration_count == 0
assert event.checked_in_count == 0
assert event.attended_count == 0
assert event.total_participants == 0
```

### Test Case 2: Registrations Only
```python
# Setup
event = Event.objects.create(title="Test Event", capacity=50)
for i in range(5):
    EventParticipant.objects.create(
        event=event,
        user=users[i],
        status='registered'
    )

# Expected
assert event.registration_count == 5
assert event.checked_in_count == 0
assert event.attended_count == 0
assert event.total_participants == 5
```

### Test Case 3: Mixed Statuses
```python
# Setup
event = Event.objects.create(title="Test Event", capacity=50)

# 3 registered
for i in range(3):
    EventParticipant.objects.create(event=event, user=users[i], status='registered')

# 2 checked in
for i in range(3, 5):
    EventParticipant.objects.create(event=event, user=users[i], status='checked_in')

# 1 attended
EventParticipant.objects.create(event=event, user=users[5], status='attended')

# 1 cancelled (should not count)
EventParticipant.objects.create(event=event, user=users[6], status='cancelled')

# Expected
assert event.registration_count == 3
assert event.checked_in_count == 2
assert event.attended_count == 1
assert event.total_participants == 6  # 3+2+1 (excludes cancelled)
```

### Test API Response
```bash
# Test with curl
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8000/api/events/3/

# Expected response
{
  "registration_count": 3,
  "checked_in_count": 2,
  "attended_count": 1,
  "total_participants": 6
}
```

---

## Django Shell Testing

```python
# Test in Django shell
python manage.py shell

from events.models import Event, EventParticipant

# Get event
event = Event.objects.get(id=3)

# Manual count
print(f"Registered: {event.eventparticipant_set.filter(status='registered').count()}")
print(f"Checked In: {event.eventparticipant_set.filter(status='checked_in').count()}")
print(f"Attended: {event.eventparticipant_set.filter(status='attended').count()}")
print(f"Total (no cancel): {event.eventparticipant_set.exclude(status='cancelled').count()}")

# Test serializer
from events.serializers import EventSerializer
serializer = EventSerializer(event)
print(serializer.data['registration_count'])
print(serializer.data['checked_in_count'])
print(serializer.data['attended_count'])
print(serializer.data['total_participants'])
```

---

## Migration Notes

### Backward Compatibility
- ✅ `registration_count` field behavior UNCHANGED for existing clients
- ✅ New fields are OPTIONAL - old clients can ignore them
- ✅ No database schema changes required
- ✅ No data migration needed

### Deployment Steps
1. Deploy backend code with new serializer fields
2. Test API responses include all 4 count fields
3. Update frontend to use new fields (optional - can stay with registration_count)
4. Monitor performance with annotations

---

## Performance Considerations

### Without Optimization (N+1 Queries)
```python
# This causes 1 query per event to calculate each count
events = Event.objects.all()  # 1 query
for event in events:
    event.registration_count  # +1 query per event
    event.checked_in_count    # +1 query per event
    event.attended_count      # +1 query per event
    event.total_participants  # +1 query per event
# Total: 1 + (N * 4) queries
```

### With Optimization (Annotations)
```python
# All counts calculated in single query
events = Event.objects.annotate(
    registered_count=Count('eventparticipant', filter=Q(eventparticipant__status='registered')),
    checked_in_count=Count('eventparticipant', filter=Q(eventparticipant__status='checked_in')),
    attended_count=Count('eventparticipant', filter=Q(eventparticipant__status='attended')),
    total_participants_count=Count('eventparticipant', filter=~Q(eventparticipant__status='cancelled')),
)
# Total: 1 query for everything
```

**Recommendation:** Use annotations for list endpoints, SerializerMethodField for detail endpoints.

---

## Common Issues & Solutions

### Issue 1: Counts Don't Match
**Symptom:** `total_participants != registration_count + checked_in_count + attended_count`

**Cause:** Participants with other statuses (e.g., 'pending')

**Solution:** 
```python
# Make sure to handle all possible statuses
PARTICIPANT_STATUSES = ['registered', 'checked_in', 'attended', 'pending', 'cancelled']

# total_participants should exclude ONLY cancelled
total = exclude(status='cancelled')
```

### Issue 2: Performance Slow
**Symptom:** API takes >1s to respond with event list

**Solution:** Use queryset annotations (see Step 2)

### Issue 3: Old Clients Breaking
**Symptom:** Mobile app crashes after backend update

**Solution:** Keep `registration_count` behavior unchanged, add new fields separately

---

## Security Considerations

### Permission Checks
Ensure users can only see participant counts they're authorized to view:

```python
class EventSerializer(serializers.ModelSerializer):
    def get_registration_count(self, obj):
        request = self.context.get('request')
        
        # Public events: anyone can see counts
        if obj.is_public:
            return obj.eventparticipant_set.filter(status='registered').count()
        
        # Private events: only club admins/system admins
        user = request.user if request else None
        if not user or not user.has_club_admin_permission(obj.club_id):
            return 0  # Hide count from unauthorized users
        
        return obj.eventparticipant_set.filter(status='registered').count()
```

---

## API Examples

### Get Event List with Counts
```http
GET /api/events/?club_id=1
Authorization: Bearer {token}

Response 200 OK:
{
  "count": 3,
  "results": [
    {
      "id": 1,
      "title": "Hackathon 2025",
      "capacity": 100,
      "registration_count": 8,
      "checked_in_count": 2,
      "attended_count": 0,
      "total_participants": 10
    },
    {
      "id": 3,
      "title": "AI Workshop",
      "capacity": 50,
      "registration_count": 0,
      "checked_in_count": 3,
      "attended_count": 0,
      "total_participants": 3
    }
  ]
}
```

### Get Single Event with Counts
```http
GET /api/events/3/
Authorization: Bearer {token}

Response 200 OK:
{
  "id": 3,
  "title": "AI Workshop - Basic",
  "capacity": 50,
  "registration_count": 0,
  "checked_in_count": 3,
  "attended_count": 0,
  "total_participants": 3,
  "start_at": "2025-11-20T10:00:00Z",
  "end_at": "2025-11-20T12:00:00Z"
}
```

---

## Checklist for Backend Team

- [ ] Update EventSerializer with 4 count fields
- [ ] Implement SerializerMethodField for each count
- [ ] Add queryset annotations for performance
- [ ] Write unit tests for all counts
- [ ] Test with Django shell
- [ ] Test API responses with curl/Postman
- [ ] Update API documentation
- [ ] Check backward compatibility
- [ ] Deploy to staging
- [ ] Coordinate with frontend team for testing
- [ ] Deploy to production

---

## Timeline Estimate

| Task | Time | Notes |
|------|------|-------|
| Code implementation | 1-2 hours | SerializerMethodField |
| Optimization (annotations) | 1 hour | Optional but recommended |
| Unit tests | 1 hour | Test all statuses |
| Manual testing | 30 min | Django shell + API calls |
| Documentation | 30 min | Update API docs |
| **Total** | **4-5 hours** | Single developer |

---

## Support & Questions

**Contact Frontend Team:**
- Share this document for coordination
- Frontend needs to update Event model (see separate guide)
- Coordinate testing after both teams implement

**Test Endpoints:**
```bash
python test_api_simple.py              # Basic count test
python test_event3_detail.py           # Detailed status breakdown
```

---

**Document Version:** 1.0  
**Last Updated:** November 15, 2024  
**Status:** 📋 Ready for Implementation
