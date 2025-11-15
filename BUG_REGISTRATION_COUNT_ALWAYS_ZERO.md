# BUG REPORT: registration_count Field Always Returns 0

## Test Date
**November 15, 2024**

## Summary
Backend API **returns** the `registration_count` field correctly in Event responses, but the **value is always 0** regardless of actual participant count.

## Test Results

### Endpoint Tested
- `GET /api/events/?club_id=1` (list)
- `GET /api/events/{id}/` (detail)

### Test Account
- Username: `tech_admin`
- Role: `club_admin`
- Club: Tech Club (id=1)

### Findings

| Event ID | Title | registration_count | Actual Participants | Status |
|----------|-------|-------------------|---------------------|--------|
| 4 | Career Seminar 2025 | 0 | 0 | ✅ CORRECT |
| 1 | Hackathon 2025 | 0 | 2 | ❌ **WRONG** |
| 3 | AI Workshop - Basic | 0 | 3 | ❌ **WRONG** |

## Evidence

### Events List Response
```json
{
  "results": [
    {
      "id": 1,
      "title": "Hackathon 2025",
      "capacity": 100,
      "registration_count": 0,    // ← SHOULD BE 2
      // ... other fields
    },
    {
      "id": 3,
      "title": "AI Workshop - Basic",
      "capacity": 50,
      "registration_count": 0,    // ← SHOULD BE 3
      // ... other fields
    }
  ]
}
```

### Actual Participants Verification
```
GET /api/events/1/participants/
→ Returns 2 participants with status='registered'

GET /api/events/3/participants/
→ Returns 3 participants with status='registered'
```

## Frontend Impact

The Event model in Flutter correctly reads the field:

```dart
// lib/features/event_management/domain/models/event.dart
class Event {
  final int participantCount;  // ← Maps from 'registration_count'
  
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      participantCount: parseInt(json['registration_count']),  // ← Gets wrong value
    );
  }
}
```

**Result:** Event cards display "0/100" instead of "2/100" participants.

## Root Cause Analysis

Likely issues in Django backend:

### 1. SerializerMethodField Not Querying Correctly

```python
# Incorrect implementation (probable current state)
class EventSerializer(serializers.ModelSerializer):
    registration_count = serializers.SerializerMethodField()
    
    def get_registration_count(self, obj):
        # ❌ Might be returning hardcoded 0
        return 0
        
        # OR
        # ❌ Might be counting ALL participants (including cancelled)
        return obj.participants.count()
        
        # OR
        # ❌ Might have wrong related_name
        return obj.registrations.count()  # If related_name doesn't exist
```

### 2. Missing/Wrong ORM Query

The correct implementation should:
- Filter by `status='registered'` (exclude cancelled, attended, etc.)
- Count EventParticipant records related to this event
- Use proper related_name

```python
# ✅ Correct implementation
def get_registration_count(self, obj):
    return obj.eventparticipant_set.filter(
        status='registered'
    ).count()
    
    # OR if you have custom related_name
    return obj.participants.filter(
        status='registered'
    ).count()
```

### 3. Annotation Issue

If using queryset annotation:

```python
# In ViewSet's get_queryset()
queryset = Event.objects.annotate(
    registration_count=Count(
        'eventparticipant',
        filter=Q(eventparticipant__status='registered')  # ← Might be missing filter
    )
)
```

## Required Fix

### Backend Team Action Items

1. **Check EventSerializer**
   - File: `events/serializers.py` (or similar)
   - Look for `registration_count` field definition
   - Verify `get_registration_count()` method logic

2. **Verify ORM Query**
   - Confirm `related_name` in EventParticipant model
   - Check if filtering by `status='registered'`
   - Test query in Django shell:
     ```python
     from events.models import Event
     event = Event.objects.get(id=1)
     count = event.eventparticipant_set.filter(status='registered').count()
     print(count)  # Should print 2, not 0
     ```

3. **Test Fix**
   - After implementing fix, test with:
     ```bash
     python test_api_simple.py
     ```
   - All events should show `[MATCH]` status

## Frontend Workaround

**Status:** ❌ Not needed if backend is fixed quickly

If backend fix is delayed:

```dart
// Fetch participants count separately
Future<int> _getActualParticipantCount(int eventId) async {
  final participants = await clubAdminRepository.getEventParticipants(eventId, status: 'registered');
  return participants.length;
}
```

But this is inefficient - better to fix backend.

## Additional Notes

### Other Numeric Fields (Working Correctly)
These fields return proper values:
- `capacity`: ✅ Correct
- `view_count`: ✅ Correct  
- `rating_count`: ✅ Correct
- `is_full`: ✅ Boolean working
- `is_registration_open`: ✅ Boolean working

Only `registration_count` is broken.

### Test Script
Automated test script available: `test_api_simple.py`

Run anytime to verify fix:
```bash
python test_api_simple.py
```

Expected output after fix:
```
Event #1: Hackathon 2025
   registration_count: 2
   Actual participants: 2
   [MATCH] registration_count is CORRECT  # ← Should show MATCH
```

## Priority
**HIGH** - Affects UX on event cards and participant management screens

## Related Documents
- `BACKEND_REQUIREMENTS.md` - Permission system requirements
- `BACKEND_BUG_PARTICIPANTS_FILTER.md` - Previous status filter bug (FIXED)
- `lib/features/event_management/domain/models/event.dart` - Frontend Event model

---
**Test Date:** November 15, 2024  
**Tested By:** Automated Script + Manual Verification  
**Status:** 🔴 CONFIRMED BUG - Awaiting Backend Fix
