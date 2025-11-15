# Frontend Implementation Guide: Multiple Participant Counts

## Overview
Hướng dẫn update Flutter app để sử dụng multiple participant counts từ backend API.

---

## Changes Summary

### Event Model Updates
**File:** `lib/features/event_management/domain/models/event.dart`

#### New Fields Added:
```dart
class Event {
  // Legacy field (kept for backward compatibility)
  final int participantCount;  // Maps to registration_count
  
  // NEW: Multiple count fields
  final int registrationCount;  // Đang đăng ký (chưa check-in)
  final int checkedInCount;     // Đã check-in (đang trong event)
  final int attendedCount;      // Đã hoàn thành tham dự
  final int totalParticipants;  // Tổng số người (trừ cancelled)
}
```

#### New Helper Methods:
```dart
// Calculate active participants
int get activeParticipants  // registrationCount + checkedInCount

// Event status checks
bool get isLive           // Event đang diễn ra
bool get hasEnded         // Event đã kết thúc
bool get isFull           // Đã đầy chỗ

// Smart display texts
String get participantDisplayText     // Text đầy đủ theo context
String get participantCountShort      // Text ngắn gọn cho cards
String get availabilityText           // "Còn 20 chỗ", "Đã đầy", etc.
```

---

## Usage Examples

### 1. Event Card Display (Recommended)

Use smart helper methods for automatic context-aware display:

```dart
// Before (Old way)
Text('${event.participantCount}/${event.capacity}')

// After (New way - Smart display)
Text(event.participantDisplayText)
```

**Output examples:**
- Before event: "10/50" (10 registered, capacity 50)
- During event: "8 đã đến / 10 đã đăng ký" (8 checked in, 10 total registered)
- After event: "10 đã tham dự" (10 people attended)

---

### 2. Short Display for Small Cards

```dart
ClubEventCardSummary(
  title: event.title,
  // Before
  registered: event.participantCount,
  
  // After - Use smart short text
  registered: event.registrationCount,  // or use helper:
  statusText: event.participantCountShort,
  capacity: event.capacity,
)
```

---

### 3. Detailed Event Page

Show all counts for transparency:

```dart
Column(
  children: [
    _buildInfoRow(
      Icons.people,
      'Đăng ký',
      '${event.registrationCount} người',
    ),
    if (event.checkedInCount > 0)
      _buildInfoRow(
        Icons.check_circle,
        'Đã check-in',
        '${event.checkedInCount} người',
      ),
    if (event.attendedCount > 0)
      _buildInfoRow(
        Icons.event_available,
        'Đã tham dự',
        '${event.attendedCount} người',
      ),
    _buildInfoRow(
      Icons.groups,
      'Tổng cộng',
      '${event.totalParticipants}/${event.capacity}',
    ),
    
    // Availability status
    Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: event.isFull ? Colors.red : Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        event.availabilityText,  // Smart text
        style: TextStyle(color: Colors.white),
      ),
    ),
  ],
)
```

---

### 4. Participants Screen Header

Show relevant count based on filter:

```dart
class EventParticipantsScreen extends StatelessWidget {
  final Event event;
  final String selectedFilter; // 'all', 'registered', 'checked_in', etc.
  
  String get headerText {
    switch (selectedFilter) {
      case 'registered':
        return '${event.registrationCount} người đã đăng ký';
      case 'checked_in':
        return '${event.checkedInCount} người đã check-in';
      case 'attended':
        return '${event.attendedCount} người đã tham dự';
      case 'all':
      default:
        return '${event.totalParticipants} người tổng cộng';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(headerText),
        Text('Capacity: ${event.capacity}'),
        
        // Use activeParticipants for availability check
        if (event.isFull)
          Text('Đã đầy', style: TextStyle(color: Colors.red)),
      ],
    );
  }
}
```

---

### 5. Status Badge Color Logic

```dart
Color getStatusColor(Event event) {
  if (event.hasEnded) {
    return Colors.grey; // Event ended
  }
  
  if (event.isFull) {
    return Colors.red; // Full
  }
  
  if (event.isLive) {
    return Colors.orange; // Happening now
  }
  
  if (event.activeParticipants > event.capacity * 0.8) {
    return Colors.yellow; // Almost full (>80%)
  }
  
  return Colors.green; // Available
}
```

---

## Migration Strategy

### Phase 1: Backward Compatible (Current)
✅ Already implemented - works with both old and new API

```dart
// If backend doesn't have new fields yet, falls back to 0
registrationCount: parseInt(json['registration_count']),  // Works
checkedInCount: parseInt(json['checked_in_count']),        // Returns 0 if missing
attendedCount: parseInt(json['attended_count']),           // Returns 0 if missing
totalParticipants: parseInt(json['total_participants']),   // Returns 0 if missing
```

### Phase 2: Update UI (After Backend Deploy)
Update screens to use new helper methods:

1. **Club Home Page** - Use `participantCountShort`
2. **Club Events Page** - Use `participantDisplayText`
3. **Event Participants Screen** - Show breakdown of all counts
4. **Event Cards** - Use `availabilityText` for badge

### Phase 3: Remove Legacy (Future)
After all systems use new fields, can remove:
- `participantCount` field (replaced by `registrationCount`)
- Old hardcoded display logic

---

## Update Checklist

### Files to Update

- [x] ✅ `lib/features/event_management/domain/models/event.dart` - Model updated
- [ ] `lib/features/event_creation/presentation/screens/club_home_page.dart`
- [ ] `lib/features/event_creation/presentation/screens/club_events_page.dart`
- [ ] `lib/features/event_creation/presentation/screens/event_participants_screen.dart`
- [ ] `lib/features/event_creation/presentation/widgets/club_event_card_summary.dart` (if exists)

### Specific Changes Needed

#### 1. Club Home Page (Line ~505)
```dart
// Current
ClubEventCardSummary(
  registered: event.participantCount,
  capacity: event.capacity,
)

// Update to
ClubEventCardSummary(
  registered: event.registrationCount,
  checkedIn: event.checkedInCount,  // Add if widget supports
  capacity: event.capacity,
  statusText: event.availabilityText,
)
```

#### 2. Club Events Page (Line ~285)
```dart
// Current
_buildInfoRow(Icons.people, 'Số người đăng ký', 
  '${event.participantCount}/${event.capacity}'),

// Update to (Smart display)
_buildInfoRow(Icons.people, 'Người tham gia', 
  event.participantDisplayText),
  
// OR (Detailed display)
Column(
  children: [
    _buildInfoRow(Icons.how_to_reg, 'Đã đăng ký', 
      '${event.registrationCount}'),
    if (event.checkedInCount > 0)
      _buildInfoRow(Icons.check_circle, 'Đã check-in', 
        '${event.checkedInCount}'),
    _buildInfoRow(Icons.people, 'Sức chứa', 
      '${event.capacity}'),
  ],
)
```

#### 3. Event Participants Screen (Line ~203)
```dart
// Current
Text(
  '${widget.event.participantCount} / ${widget.event.capacity}',
  style: TextStyle(color: Colors.grey.shade700),
),

// Update to (Smart display)
Text(
  widget.event.participantDisplayText,
  style: TextStyle(color: Colors.grey.shade700),
),

// OR show breakdown
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Đăng ký: ${widget.event.registrationCount}'),
    Text('Đã check-in: ${widget.event.checkedInCount}'),
    Text('Đã tham dự: ${widget.event.attendedCount}'),
    Divider(),
    Text('Tổng: ${widget.event.totalParticipants}/${widget.event.capacity}',
      style: TextStyle(fontWeight: FontWeight.bold)),
  ],
)
```

#### 4. Full/Available Badge (Line ~210)
```dart
// Current
Container(
  decoration: BoxDecoration(
    color: widget.event.participantCount >= widget.event.capacity
        ? Colors.red
        : Colors.green,
  ),
  child: Text(
    widget.event.participantCount >= widget.event.capacity
        ? 'Đã đầy'
        : 'Còn chỗ',
  ),
)

// Update to (Use helper)
Container(
  decoration: BoxDecoration(
    color: widget.event.isFull ? Colors.red : Colors.green,
  ),
  child: Text(widget.event.availabilityText),  // Smart text
)
```

---

## Testing

### Manual Test Cases

#### Test Case 1: Event with Only Registrations
**Backend returns:**
```json
{
  "registration_count": 10,
  "checked_in_count": 0,
  "attended_count": 0,
  "total_participants": 10,
  "capacity": 50
}
```

**Expected Display:**
- Card: "10/50"
- Detail: "10 người đã đăng ký"
- Badge: "Còn 40 chỗ" (green)

#### Test Case 2: Event During (Some Checked In)
**Backend returns:**
```json
{
  "registration_count": 2,
  "checked_in_count": 8,
  "attended_count": 0,
  "total_participants": 10,
  "capacity": 50
}
```

**Expected Display:**
- Card: "8 đã đến / 10 đã đăng ký"
- Detail: "8 người đã check-in, 2 người chưa đến"
- Badge: "Còn 40 chỗ" (green)

#### Test Case 3: Event Ended
**Backend returns:**
```json
{
  "registration_count": 0,
  "checked_in_count": 0,
  "attended_count": 10,
  "total_participants": 10,
  "capacity": 50
}
```

**Expected Display:**
- Card: "10 đã tham dự"
- Detail: "10 người đã hoàn thành event"
- Badge: "Đã kết thúc" (grey)

#### Test Case 4: Full Event
**Backend returns:**
```json
{
  "registration_count": 50,
  "checked_in_count": 0,
  "attended_count": 0,
  "total_participants": 50,
  "capacity": 50
}
```

**Expected Display:**
- Card: "50/50"
- Detail: "50 người đã đăng ký"
- Badge: "Đã đầy" (red)
- `event.isFull` returns `true`

### Automated Testing

```dart
// test/models/event_test.dart
void main() {
  group('Event Multiple Counts', () {
    test('activeParticipants calculates correctly', () {
      final event = Event(
        id: '1',
        title: 'Test Event',
        registrationCount: 5,
        checkedInCount: 3,
        attendedCount: 0,
        totalParticipants: 8,
        capacity: 50,
      );
      
      expect(event.activeParticipants, 8); // 5 + 3
    });
    
    test('isFull returns true when capacity reached', () {
      final event = Event(
        id: '1',
        title: 'Test Event',
        registrationCount: 50,
        checkedInCount: 0,
        attendedCount: 0,
        totalParticipants: 50,
        capacity: 50,
      );
      
      expect(event.isFull, true);
    });
    
    test('participantDisplayText shows correctly for ongoing event', () {
      final event = Event(
        id: '1',
        title: 'Test Event',
        registrationCount: 2,
        checkedInCount: 8,
        attendedCount: 0,
        totalParticipants: 10,
        capacity: 50,
        startAt: DateTime.now().subtract(Duration(hours: 1)),
        endAt: DateTime.now().add(Duration(hours: 1)),
      );
      
      expect(event.isLive, true);
      expect(event.participantDisplayText, contains('đã đến'));
    });
  });
}
```

---

## API Response Examples

### Before Backend Update
```json
{
  "id": 1,
  "title": "Hackathon 2025",
  "capacity": 100,
  "registration_count": 10
}
```
**Frontend handles gracefully:**
- `registrationCount`: 10 ✅
- `checkedInCount`: 0 (default)
- `attendedCount`: 0 (default)
- `totalParticipants`: 0 (default)

### After Backend Update
```json
{
  "id": 1,
  "title": "Hackathon 2025",
  "capacity": 100,
  "registration_count": 2,
  "checked_in_count": 8,
  "attended_count": 0,
  "total_participants": 10
}
```
**Frontend uses all fields:**
- `registrationCount`: 2 ✅
- `checkedInCount`: 8 ✅
- `attendedCount`: 0 ✅
- `totalParticipants`: 10 ✅
- `activeParticipants`: 10 (calculated) ✅

---

## Performance Notes

### No Additional API Calls
All counts come from single event API response - no extra network requests needed.

### Minimal Memory Impact
```dart
// 4 additional int fields per Event object
// Each int = 8 bytes
// Total overhead = 32 bytes per event
// For 100 events = 3.2KB (negligible)
```

### Computation Cost
Helper methods use simple arithmetic - O(1) complexity, no loops.

---

## Rollback Plan

If issues occur, can easily rollback:

### Step 1: Keep using old field
```dart
// Revert to old display
Text('${event.participantCount}/${event.capacity}')
// participantCount still works (maps to registration_count)
```

### Step 2: Remove helper method usage
```dart
// Replace helper methods with direct field access
event.isFull  →  event.participantCount >= event.capacity
```

### Step 3: Frontend keeps working
New fields default to 0 if not in API response - no crashes.

---

## Common Questions

### Q: What if backend only implements some fields?
**A:** Frontend gracefully handles missing fields by defaulting to 0.

### Q: Should I update all screens at once?
**A:** No, update incrementally:
1. Keep existing displays working
2. Add new displays where most valuable
3. Gradually adopt helper methods

### Q: Can I still use `participantCount`?
**A:** Yes! It's kept for backward compatibility. Equals `registrationCount`.

### Q: What about performance?
**A:** No impact - all counts come in same API response, helpers are simple getters.

---

## Timeline

| Task | Time Estimate |
|------|---------------|
| Model already updated | ✅ Done |
| Update 1 screen (test) | 15-30 min |
| Update all screens | 1-2 hours |
| Testing | 30 min |
| Code review | 15 min |
| **Total** | **2-3 hours** |

---

## Next Steps

1. ✅ Event model updated with new fields and helpers
2. ⏳ Wait for backend team to deploy multiple counts
3. ⏳ Test with `python test_api_simple.py` to verify API
4. ⏳ Update screens to use helper methods
5. ⏳ Test all display scenarios
6. ⏳ Deploy to production

---

## Support

**Backend Guide:** See `BACKEND_GUIDE_MULTIPLE_PARTICIPANT_COUNTS.md`

**Questions?** Check helper method implementations in Event model.

**Issues?** Fields default to 0 safely - no crashes expected.

---

**Document Version:** 1.0  
**Last Updated:** November 15, 2024  
**Status:** ✅ Model Updated - Ready for Screen Updates
