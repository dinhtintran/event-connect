# 🚀 Quick Reference - API Integration

## 📍 Base URL Configuration
```dart
// lib/core/config/app_config.dart
static const String apiBaseUrl = 'http://127.0.0.1:8000/';

// Android Emulator: http://10.0.2.2:8000/
// iOS Simulator: http://localhost:8000/
// Real Device: http://YOUR_IP:8000/
```

---

## 🎯 Using EventService in Widgets

### Read Data (Auto rebuild on change)
```dart
final eventService = context.watch<EventService>();
final events = eventService.allEvents;
final isLoading = eventService.isLoading;
final error = eventService.error;
```

### Call Methods (No rebuild)
```dart
context.read<EventService>().loadAllEvents();
context.read<EventService>().registerForEvent('event-id');
```

### In initState
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<EventService>().loadAllEvents();
  });
}
```

---

## 📊 Available Methods

### EventService
```dart
// Load data
await eventService.loadAllEvents();
await eventService.loadFeaturedEvents();
await eventService.loadMyRegisteredEvents();
await eventService.loadEventsByCategory('Công nghệ');

// Search
final results = await eventService.searchEvents('hackathon');

// Register/Unregister
await eventService.registerForEvent('event-id');
await eventService.unregisterFromEvent('event-id');

// Feedback
await eventService.submitFeedback('event-id', 4.5, 'Great event!');

// Filters
eventService.setCategory('Âm nhạc');
final filtered = eventService.filteredEvents;
final upcoming = eventService.upcomingEvents;
final past = eventService.pastEvents;

// Refresh
await eventService.refreshAll();
```

---

## 🔗 API Endpoints Quick Reference

### Events
```
GET    /api/events/                  # All events
GET    /api/events/{id}/             # Event detail
GET    /api/events/featured/         # Featured events
GET    /api/events/search/?q=query   # Search
GET    /api/events/?category=tech    # Filter by category
POST   /api/events/{id}/register/    # Register
POST   /api/events/{id}/unregister/  # Unregister
```

### Registrations
```
GET    /api/registrations/my-events/  # My registered events
```

### Feedback
```
POST   /api/events/{id}/feedback/     # Submit feedback
GET    /api/events/{id}/feedbacks/    # Get feedbacks
```

### Clubs
```
GET    /api/clubs/                     # All clubs
GET    /api/clubs/{id}/                # Club detail
POST   /api/clubs/{id}/events/        # Create event (Club Admin)
```

### Notifications
```
GET    /api/notifications/             # All notifications
POST   /api/notifications/{id}/read/   # Mark as read
GET    /api/notifications/unread-count/ # Unread count
```

### Admin
```
GET    /api/admin/stats/               # Dashboard stats
GET    /api/admin/activities/          # Recent activities
GET    /api/admin/users/               # User management
```

### Approvals
```
GET    /api/approvals/pending/         # Pending events
POST   /api/approvals/{id}/approve/    # Approve event
POST   /api/approvals/{id}/reject/     # Reject event
```

---

## 🎨 UI Patterns

### Loading State
```dart
if (eventService.isLoading && eventService.allEvents.isEmpty) {
  return Center(child: CircularProgressIndicator());
}
```

### Error State
```dart
if (eventService.error != null) {
  return Center(
    child: Text('Error: ${eventService.error}'),
  );
}
```

### Empty State
```dart
if (eventService.allEvents.isEmpty) {
  return Center(
    child: Text('No events found'),
  );
}
```

### Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: () => context.read<EventService>().loadAllEvents(),
  child: ListView(...),
)
```

---

## 🐛 Common Issues & Solutions

### Issue: "Undefined name 'EventService'"
**Solution**: Add import
```dart
import 'package:event_connect/features/event_management/domain/services/event_service.dart';
```

### Issue: "Connection refused"
**Solution**: Check backend URL
```dart
// For Android Emulator
apiBaseUrl = 'http://10.0.2.2:8000/';
```

### Issue: "No Provider found"
**Solution**: Make sure EventService is in main.dart
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => EventService(...)),
  ],
)
```

### Issue: "Token not included in request"
**Solution**: Already handled by TokenInterceptor

### Issue: "CORS error on web"
**Solution**: Add CORS in Django backend
```python
CORS_ALLOWED_ORIGINS = ["http://localhost:58999"]
```

---

## 📱 Testing Commands

```bash
# Run on Chrome
flutter run -d chrome

# Run on Android Emulator
flutter run -d emulator-5554

# Run on iOS Simulator
flutter run -d "iPhone 14"

# Check for errors
flutter analyze

# Hot reload
Press 'r' in terminal

# Hot restart
Press 'R' in terminal

# Quit
Press 'q' in terminal
```

---

## 📂 File Locations

```
Core Files:
lib/core/config/app_config.dart          # Base URL
lib/main.dart                            # Provider setup

Event Management:
lib/features/event_management/
  ├── data/api/event_api.dart            # API calls
  ├── data/repositories/event_repository.dart
  └── domain/services/event_service.dart # State management

Screens:
lib/features/event_management/presentation/screens/
  ├── home_screen.dart
  ├── explore_screen.dart
  ├── my_events_screen.dart
  └── event_detail_screen.dart

Additional APIs:
lib/core/api/
  ├── notification_api.dart
  ├── club_api.dart
  ├── admin_api.dart
  └── approval_api.dart
```

---

## 🎓 Learning Resources

**Flutter Provider**: https://pub.dev/packages/provider  
**Dio HTTP**: https://pub.dev/packages/dio  
**Flutter Architecture**: `ARCHITECTURE.md` in project  
**Feature Development**: `FEATURE_DEVELOPMENT_GUIDE.md`

---

## ✅ Pre-flight Checklist

Before running:
- [ ] Backend server running
- [ ] Base URL configured
- [ ] `flutter pub get` executed
- [ ] No compile errors
- [ ] Device/emulator ready

---

**Quick Start**: `flutter run` 🚀
