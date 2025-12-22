# 🐛 Frontend Bug: Incorrect Event ID Used in Unregister API

## Issue Summary

**Status**: 🔴 Critical Frontend Bug  
**Component**: Event Registration/Unregister  
**Root Cause**: Frontend is using `registration.id` instead of `registration.event.id` when calling unregister API

---

## Problem Description

When a user tries to unregister from an event, the Flutter app is sending the **wrong ID** to the backend API, causing 404 errors.

### Current Behavior (❌ Wrong)

```
User clicks "Cancel Event" button
→ Frontend calls: POST /api/events/14/unregister/
→ Backend returns: 404 Not Found
→ Event ID 14 does not exist in database
```

### Expected Behavior (✅ Correct)

```
User clicks "Cancel Event" button
→ Frontend calls: POST /api/events/7/unregister/
→ Backend returns: 200 OK
→ Registration successfully deleted
```

---

## Root Cause Analysis

### API Response Structure

The `/api/registrations/my-events/` endpoint returns:

```json
{
  "count": 1,
  "results": [
    {
      "id": 14,                    // ❌ This is Registration ID (record ID)
      "event": {
        "id": 7,                   // ✅ This is Event ID (use this!)
        "title": "Test Event for Approval",
        "slug": "test-event-for-approval",
        "status": "approved",
        // ... other event fields
      },
      "user": { ... },
      "status": "registered",
      "qr_code": "EVT-7-USR-4-10121B52",
      "registered_at": "2025-11-18T10:00:00Z"
    }
  ]
}
```

### The Confusion

- **`registration.id`** = Primary key of EventRegistration table (can be any number: 1, 14, 99, etc.)
- **`registration.event.id`** = Primary key of Event table (the actual event ID)

These are **DIFFERENT values** and **NOT interchangeable**!

---

## Evidence from Backend

### Database Check

```bash
# Events in database
ID 2: Spring Concert 2025
ID 5: Campus Marathon 2025
ID 6: Python Programming Competition
ID 7: Test Event for Approval

# student1's registration
Registration ID: 14
└─ Points to Event ID: 7
```

### API Test Results

```bash
# ❌ WRONG - Using registration ID
POST /api/events/14/unregister/
Response: 404 Not Found
Reason: Event ID 14 does not exist

# ✅ CORRECT - Using event ID
POST /api/events/7/unregister/
Response: 200 OK
Message: "Successfully unregistered from event"
```

---

## Fix Required in Flutter

### Location to Fix

Search for where the unregister API is called. Likely in:
- `lib/services/event_service.dart`
- `lib/services/event_api.dart`
- Or wherever registration cancellation is handled

### Code Changes

#### ❌ Current Code (WRONG)

```dart
// WRONG: Using registration ID instead of event ID
Future<void> unregisterFromEvent(Registration registration) async {
  final response = await _dio.post(
    '/events/${registration.id}/unregister/',  // ❌ This is registration.id
  );
}
```

#### ✅ Fixed Code (CORRECT)

```dart
// CORRECT: Using event ID from nested event object
Future<void> unregisterFromEvent(Registration registration) async {
  final response = await _dio.post(
    '/events/${registration.event.id}/unregister/',  // ✅ This is event.id
  );
}
```

### Alternative Approach

If you want to keep the parameter as just an event ID:

```dart
// Option 1: Pass event ID directly
Future<void> unregisterFromEvent(int eventId) async {
  final response = await _dio.post('/events/$eventId/unregister/');
}

// Call it like:
await unregisterFromEvent(registration.event.id);

// Option 2: Keep Registration object but extract event ID
Future<void> unregisterFromEvent(Registration registration) async {
  final eventId = registration.event.id;
  final response = await _dio.post('/events/$eventId/unregister/');
}
```

---

## How to Verify the Fix

### Step 1: Check Your Model Classes

Make sure your Dart models have the correct structure:

```dart
class Registration {
  final int id;                    // Registration ID
  final Event event;               // Nested Event object
  final User user;
  final String status;
  final String qrCode;
  final DateTime registeredAt;
  
  // ... constructor, fromJson, etc.
}

class Event {
  final int id;                    // Event ID - USE THIS for unregister!
  final String title;
  final String slug;
  // ... other fields
}
```

### Step 2: Add Logging

Add debug logs to verify correct ID is being used:

```dart
Future<void> unregisterFromEvent(Registration registration) async {
  print('🔴 Registration ID: ${registration.id}');           // For debugging only
  print('✅ Event ID: ${registration.event.id}');            // This should be used
  print('📤 Calling: POST /events/${registration.event.id}/unregister/');
  
  final response = await _dio.post(
    '/events/${registration.event.id}/unregister/',
  );
  
  print('📥 Response: ${response.statusCode}');
}
```

### Step 3: Test

1. Login to the app
2. Go to "My Events" page
3. Try to cancel an event
4. Check the logs - should see:
   ```
   🔴 Registration ID: 14
   ✅ Event ID: 7
   📤 Calling: POST /events/7/unregister/
   📥 Response: 200
   ```

---

## API Documentation Reference

### Correct Unregister Endpoint

**Endpoint**: `POST /api/events/{event_id}/unregister/`

**Parameters**:
- `event_id` (path parameter): The **Event ID**, NOT the Registration ID

**Example**:
```bash
# ✅ CORRECT
POST /api/events/7/unregister/
Authorization: Bearer <token>

# ❌ WRONG
POST /api/events/14/unregister/  # If 14 is registration ID
```

**Success Response** (200):
```json
{
  "message": "Successfully unregistered from event",
  "event_id": 7
}
```

**Error Response** (404):
```json
{
  "detail": "Event with ID 14 does not exist"
}
```

**Error Response** (400):
```json
{
  "error": "Not registered for this event"
}
```

---

## Related Endpoints

For reference, here are the related endpoints and their correct usage:

### 1. Get My Registered Events
```
GET /api/registrations/my-events/
```
Returns list of Registration objects with nested Event objects.

### 2. Register for Event
```
POST /api/events/{event_id}/register/
```
Uses Event ID (correct).

### 3. Unregister from Event
```
POST /api/events/{event_id}/unregister/
```
Uses Event ID (must match the one used for registration).

### 4. Check-in to Event
```
POST /api/events/{event_id}/checkin/
```
Uses Event ID (correct).

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Using Registration ID
```dart
// WRONG
final registrationId = registration.id;
await unregister(registrationId);
```

### ❌ Mistake 2: Confusing the Nested Structure
```dart
// WRONG - registration.eventId doesn't exist
await unregister(registration.eventId);
```

### ❌ Mistake 3: Hardcoding IDs for Testing
```dart
// WRONG - never hardcode IDs
await unregister(14);  // This might be registration ID!
```

### ✅ Correct Approach
```dart
// CORRECT - use nested event.id
final eventId = registration.event.id;
await unregister(eventId);

// Or directly:
await unregister(registration.event.id);
```

---

## Testing Checklist

After implementing the fix, verify:

- [ ] User can successfully unregister from an event
- [ ] API returns 200 status code (not 404)
- [ ] Event disappears from "My Events" list
- [ ] Backend logs show correct event ID in request
- [ ] No console errors related to 404

---

## Additional Notes

### Why This Bug Happened

The `/api/registrations/my-events/` response has TWO different IDs:
1. **Registration ID** (outer `id` field)
2. **Event ID** (nested `event.id` field)

It's easy to accidentally use the wrong one, especially if the model parsing or variable naming is unclear.

### Prevention

To prevent similar bugs:

1. **Use descriptive variable names**:
   ```dart
   // Good
   final eventId = registration.event.id;
   final registrationId = registration.id;
   
   // Bad
   final id = registration.id;  // Which ID?
   ```

2. **Add type safety**:
   ```dart
   Future<void> unregisterFromEvent({required int eventId}) async {
     // Parameter name makes it clear what's expected
   }
   ```

3. **Add assertions in debug mode**:
   ```dart
   assert(eventId > 0, 'Event ID must be positive');
   assert(registration.event.id == eventId, 'Event ID mismatch');
   ```

---

## Backend Status

✅ **Backend is working correctly**
- API endpoints are functioning as designed
- Error messages are accurate (404 means event not found)
- No orphaned registrations in database
- All data structures are correct

❌ **Frontend needs to be fixed**
- Must use `registration.event.id` instead of `registration.id`

---

## Questions?

If you need clarification or help implementing the fix:
1. Check the API response structure carefully
2. Verify your Dart model classes match the backend response
3. Add logging to see which ID is being sent
4. Test with a known good event ID first

**Backend Developer Contact**: Available for questions about API structure or testing
