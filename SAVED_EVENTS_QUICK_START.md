# 🚀 SAVED EVENTS - QUICK START GUIDE

## ✅ Status: Frontend Ready, Waiting for Backend

---

## 📱 User Flow

### Save Event
1. User browses events (Explore/Featured/Detail)
2. Click **❤️ Heart icon** (top-right of event poster)
3. Icon changes: white outline → **red filled**
4. SnackBar shows: "Đã lưu sự kiện"
5. Event appears in **My Events → Đã lưu tab**

### Unsave Event
1. User in EventDetailScreen or My Events → Đã lưu
2. Click **❤️ filled heart icon**
3. Icon changes: red filled → **white outline**
4. SnackBar shows: "Đã bỏ lưu sự kiện"
5. Event removed from saved list

---

## 🔌 Backend API Checklist

Backend team needs to implement these endpoints:

- [ ] `GET /api/events/saved/` - List saved events
- [ ] `POST /api/events/{id}/save/` - Save event
- [ ] `POST /api/events/{id}/unsave/` - Unsave event  
- [ ] `GET /api/events/{id}/is-saved/` - Check saved status
- [ ] Add `is_saved` field to all event responses

**Details:** See `BACKEND_TODO_SAVED_EVENTS.md`

---

## 🧪 Quick Test (When Backend Ready)

### Test 1: Basic Save/Unsave
```bash
1. Login as student
2. Go to event detail
3. Click heart icon → should turn red
4. Go to My Events → Đã lưu tab
5. Event should appear in list
6. Click heart again → should turn white
7. Refresh → event should disappear from saved list
```

### Test 2: Cross-Screen Sync
```bash
1. Save event from Explore screen
2. Go to event detail → heart should be red
3. Go to My Events → Đã lưu → event should be there
4. Unsave from detail screen
5. Check My Events → event should disappear
```

### Test 3: Persistence
```bash
1. Save 3 events
2. Logout
3. Login again
4. My Events → Đã lưu → should have 3 events
```

---

## 📂 Modified Files

```
lib/features/event_management/
├── domain/
│   ├── models/
│   │   └── event.dart                    ← Added isSaved, savedAt
│   └── services/
│       └── event_service.dart            ← Added 5 saved methods
├── data/
│   ├── api/
│   │   └── event_api.dart                ← Added 4 API methods
│   └── repositories/
│       └── event_repository.dart         ← Added 4 repo methods
└── presentation/
    └── screens/
        ├── my_events_screen.dart         ← 4 tabs, saved tab
        └── event_detail_screen.dart      ← Favorite button
```

---

## 🐛 Troubleshooting

### Issue: "Failed to get saved events"
**Cause:** Backend API not ready or endpoint returns error  
**Solution:** Check backend logs, verify endpoint exists

### Issue: Heart icon not changing
**Cause:** Network error or API returning wrong status code  
**Solution:** Check network connection, backend response format

### Issue: Saved events not showing
**Cause:** `loadSavedEvents()` not called or API returns empty list  
**Solution:** Check initState() in MyEventsScreen, verify backend data

### Issue: Cross-screen inconsistency
**Cause:** `_updateEventSavedStatus()` not working  
**Solution:** Check EventService state management, reload app

---

## 💻 Code Snippets

### Check if event is saved
```dart
final isSaved = event.isSaved;
```

### Toggle save/unsave
```dart
final eventService = Provider.of<EventService>(context, listen: false);
final success = await eventService.toggleSaveEvent(event);
```

### Get saved events list
```dart
final savedEvents = eventService.savedEvents;
```

### Manually save event
```dart
await eventService.saveEvent(eventId);
```

### Manually unsave event
```dart
await eventService.unsaveEvent(eventId);
```

---

## 📊 Expected Backend Response Formats

### GET /api/events/saved/
```json
{
  "results": [
    {
      "id": "1",
      "title": "Event Name",
      "is_saved": true,
      "saved_at": "2025-11-18T10:30:00Z",
      ...
    }
  ]
}
```

### POST /api/events/{id}/save/
```json
{
  "message": "Event saved successfully",
  "saved_at": "2025-11-18T10:30:00Z"
}
```

### POST /api/events/{id}/unsave/
```json
{
  "message": "Event unsaved successfully"
}
```

---

## 🎯 Success Criteria

- ✅ User can save events from detail screen
- ✅ Saved events appear in "Đã lưu" tab
- ✅ User can unsave events anytime
- ✅ Saved status syncs across screens
- ✅ Saved status persists after logout/login
- ✅ UI provides clear feedback (SnackBar)
- ✅ No crashes or errors during save/unsave

---

## 📞 Quick Links

- **Full Implementation Details:** `SAVED_EVENTS_IMPLEMENTATION_SUMMARY.md`
- **Backend Requirements:** `BACKEND_TODO_SAVED_EVENTS.md`
- **Frontend Guide:** `FRONTEND_TODO_SAVED_EVENTS.md`

---

**Last Updated:** November 18, 2025  
**Version:** 1.0.0  
**Status:** ✅ Frontend Complete, 🔄 Backend In Progress
