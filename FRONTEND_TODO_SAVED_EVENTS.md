# 📱 FRONTEND IMPLEMENTATION - Saved Events Feature

## 🎯 Overview
Hướng dẫn implement tính năng "Lưu sự kiện" sau khi Backend API đã sẵn sàng.

---

## ⚠️ Current Status

**Tạm thời ẨN:**
- ❌ Tab "Đã lưu" trong MyEventsScreen (line 24: 3 tabs thay vì 4)
- ❌ Button "Favorite" trong EventDetailScreen (commented out)

**Lý do:** Backend chưa có API endpoint cho saved events.

---

## 🔧 Frontend Implementation Steps

### Step 1: Update Event Model

**File:** `lib/features/event_management/domain/models/event.dart`

Thêm field `isSaved`:

```dart
class Event {
  final int id;
  // ... existing fields ...
  final bool isSaved;           // ✨ NEW field
  final DateTime? savedAt;      // ✨ NEW field (optional)

  Event({
    required this.id,
    // ... existing fields ...
    this.isSaved = false,        // ✨ Default false
    this.savedAt,                // ✨ Null if not saved
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      // ... existing fields parsing ...
      isSaved: json['is_saved'] as bool? ?? false,        // ✨ Parse from API
      savedAt: json['saved_at'] != null 
          ? DateTime.parse(json['saved_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // ... existing fields ...
      'is_saved': isSaved,        // ✨ Include in JSON
      'saved_at': savedAt?.toIso8601String(),
    };
  }
}
```

---

### Step 2: Add API Methods

**File:** `lib/features/event_management/data/api/event_api.dart`

```dart
class EventApi {
  // ... existing methods ...

  /// GET /api/events/saved/ - Lấy danh sách sự kiện đã lưu
  Future<Map<String, dynamic>> getSavedEvents({int page = 1}) async {
    _dbg('GET /api/events/saved/?page=$page');
    try {
      final res = await dio.get('/api/events/saved/', queryParameters: {
        'page': page,
      });
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// POST /api/events/{eventId}/save/ - Lưu sự kiện
  Future<Map<String, dynamic>> saveEvent(int eventId) async {
    _dbg('POST /api/events/$eventId/save/');
    try {
      final res = await dio.post('/api/events/$eventId/save/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// POST /api/events/{eventId}/unsave/ - Bỏ lưu sự kiện
  Future<Map<String, dynamic>> unsaveEvent(int eventId) async {
    _dbg('POST /api/events/$eventId/unsave/');
    try {
      final res = await dio.post('/api/events/$eventId/unsave/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// GET /api/events/{eventId}/is-saved/ - Kiểm tra đã lưu chưa
  Future<Map<String, dynamic>> isEventSaved(int eventId) async {
    _dbg('GET /api/events/$eventId/is-saved/');
    try {
      final res = await dio.get('/api/events/$eventId/is-saved/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }
}
```

---

### Step 3: Add Repository Methods

**File:** `lib/features/event_management/data/repositories/event_repository.dart`

```dart
class EventRepository {
  // ... existing methods ...

  /// Lấy danh sách sự kiện đã lưu
  Future<List<Event>> getSavedEvents({int page = 1}) async {
    final result = await api.getSavedEvents(page: page);
    if (result['status'] == 200) {
      return _parseEventList(result['body']);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to get saved events');
    }
  }

  /// Lưu sự kiện
  Future<bool> saveEvent(int eventId) async {
    final result = await api.saveEvent(eventId);
    return result['status'] == 201 || result['status'] == 200;
  }

  /// Bỏ lưu sự kiện
  Future<bool> unsaveEvent(int eventId) async {
    final result = await api.unsaveEvent(eventId);
    return result['status'] == 200;
  }

  /// Toggle save/unsave
  Future<bool> toggleSaveEvent(int eventId, bool currentlySaved) async {
    if (currentlySaved) {
      return await unsaveEvent(eventId);
    } else {
      return await saveEvent(eventId);
    }
  }
}
```

---

### Step 4: Add Service Methods

**File:** `lib/features/event_management/domain/services/event_service.dart`

```dart
class EventService extends ChangeNotifier {
  // ... existing fields ...
  List<Event> _savedEvents = [];
  
  List<Event> get savedEvents => _savedEvents;

  /// Load saved events
  Future<void> loadSavedEvents() async {
    try {
      _savedEvents = await _repository.getSavedEvents();
      notifyListeners();
    } catch (e) {
      print('Error loading saved events: $e');
    }
  }

  /// Save event
  Future<bool> saveEvent(int eventId) async {
    try {
      final success = await _repository.saveEvent(eventId);
      if (success) {
        // Reload saved events list
        await loadSavedEvents();
        // Update the event in other lists
        _updateEventSavedStatus(eventId, true);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error saving event: $e');
      return false;
    }
  }

  /// Unsave event
  Future<bool> unsaveEvent(int eventId) async {
    try {
      final success = await _repository.unsaveEvent(eventId);
      if (success) {
        // Reload saved events list
        await loadSavedEvents();
        // Update the event in other lists
        _updateEventSavedStatus(eventId, false);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error unsaving event: $e');
      return false;
    }
  }

  /// Toggle save/unsave
  Future<bool> toggleSaveEvent(Event event) async {
    return event.isSaved 
        ? await unsaveEvent(event.id)
        : await saveEvent(event.id);
  }

  /// Helper: Update saved status in all event lists
  void _updateEventSavedStatus(int eventId, bool isSaved) {
    // Update in all events
    for (var i = 0; i < _allEvents.length; i++) {
      if (_allEvents[i].id == eventId) {
        _allEvents[i] = Event.fromJson({
          ..._allEvents[i].toJson(),
          'is_saved': isSaved,
        });
      }
    }
    // Update in featured events
    for (var i = 0; i < _featuredEvents.length; i++) {
      if (_featuredEvents[i].id == eventId) {
        _featuredEvents[i] = Event.fromJson({
          ..._featuredEvents[i].toJson(),
          'is_saved': isSaved,
        });
      }
    }
  }
}
```

---

### Step 5: Update MyEventsScreen

**File:** `lib/features/event_management/presentation/screens/my_events_screen.dart`

#### Uncomment code đã bị comment:

1. **Line 24:** Đổi từ `length: 3` thành `length: 4`
2. **Line 82:** Uncomment `final savedEvents = getSavedEvents(eventService);`
3. **Line 122:** Uncomment tab `Tab(text: 'Đã lưu')`
4. **Line 103:** Uncomment `_buildEventsList(savedEvents, isUpcoming: true, isSaved: true)`

#### Update getSavedEvents():

```dart
List<Event> getSavedEvents(EventService eventService) {
  return eventService.savedEvents;  // ✅ Get from service
}
```

#### Add initState load:

```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 4, vsync: this);  // 4 tabs now
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<EventService>().loadMyRegisteredEvents();
    context.read<EventService>().loadSavedEvents();  // ✨ Load saved events
  });
}
```

---

### Step 6: Update EventDetailScreen

**File:** `lib/features/event_management/presentation/screens/event_detail_screen.dart`

#### Uncomment Favorite button (line ~290-310):

Xóa comment marks để hiển thị lại button Favorite.

#### Update onTap handler:

```dart
GestureDetector(
  onTap: () async {
    // Toggle save/unsave
    final eventService = Provider.of<EventService>(context, listen: false);
    final success = await eventService.toggleSaveEvent(widget.event);
    
    if (success) {
      setState(() {
        isFavorite = !isFavorite;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite 
                ? 'Đã lưu sự kiện' 
                : 'Đã bỏ lưu sự kiện'
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra, vui lòng thử lại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: Container(
    // ... existing Container code ...
  ),
)
```

#### Update initState:

```dart
@override
void initState() {
  super.initState();
  isFavorite = widget.event.isSaved;  // ✨ Initialize from event data
}
```

---

### Step 7: Update EventCard widgets

Nếu có button save/unsave trong EventCard, update tương tự như EventDetailScreen.

---

## 🧪 Testing Checklist

Sau khi implement xong, test các scenarios:

### Test Case 1: Save Event
1. Vào EventDetailScreen
2. Click button Favorite (trái tim)
3. Verify icon đổi từ outline → filled màu đỏ
4. Verify SnackBar "Đã lưu sự kiện"
5. Vào MyEvents → Tab "Đã lưu"
6. Verify sự kiện xuất hiện trong danh sách

### Test Case 2: Unsave Event
1. Vào MyEvents → Tab "Đã lưu"
2. Click vào một sự kiện đã lưu
3. Click button Favorite lần nữa
4. Verify icon đổi từ filled → outline
5. Verify SnackBar "Đã bỏ lưu sự kiện"
6. Back về MyEvents → Tab "Đã lưu"
7. Verify sự kiện biến mất khỏi danh sách

### Test Case 3: Saved Status Persistence
1. Save một sự kiện
2. Logout
3. Login lại
4. Vào MyEvents → Tab "Đã lưu"
5. Verify sự kiện vẫn có trong danh sách

### Test Case 4: Cross-Screen Consistency
1. Save sự kiện từ Explore screen
2. Vào EventDetailScreen của sự kiện đó
3. Verify icon Favorite hiển thị filled (đỏ)
4. Vào MyEvents → Tab "Đã lưu"
5. Verify sự kiện có trong danh sách

---

## 📝 Code Locations to Uncomment

### my_events_screen.dart
- **Line 24:** `length: 3` → `length: 4`
- **Line 82:** Uncomment `final savedEvents = getSavedEvents(eventService);`
- **Line 122:** Uncomment `Tab(text: 'Đã lưu')`
- **Line 103:** Uncomment `_buildEventsList(savedEvents, ...)`

### event_detail_screen.dart
- **Line ~290-310:** Uncomment entire GestureDetector block cho Favorite button

---

## 🚀 Deployment Steps

1. ✅ Backend API endpoints sẵn sàng và tested
2. ✅ Update Event model với `isSaved` field
3. ✅ Add API methods trong EventApi
4. ✅ Add repository methods
5. ✅ Add service methods và state management
6. ✅ Uncomment UI components
7. ✅ Update event handlers
8. 🧪 Test tất cả scenarios
9. 🚀 Deploy to staging
10. ✅ QA testing
11. 🚀 Production release

---

## 📞 Support

Nếu gặp vấn đề trong quá trình implement, check:
- Backend API documentation: `BACKEND_TODO_SAVED_EVENTS.md`
- API response format có đúng spec không
- Authentication token có được gửi đúng không
- Error handling cho các edge cases

---

**Priority:** Medium (sau khi backend ready)
**Estimated Time:** 4-6 hours
**Dependencies:** Backend API must be completed first
