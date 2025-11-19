# 🐛 Bug Fix: Event Registration Not Showing in My Events

## ❌ **Vấn đề**

Sau khi đăng ký sự kiện thành công trong `EventDetailScreen`:
- ✅ API call thành công (201 Created)
- ✅ SnackBar hiển thị "Đăng ký sự kiện thành công!"
- ✅ Button đổi thành "Check-in"
- ❌ **Sự kiện KHÔNG hiện trong "My Events" screen**

---

## 🔍 **Root Cause**

### **Flow hiện tại** (Before Fix):

```
EventDetailScreen._handleRegister()
    ↓
POST /api/events/{id}/register/ ✅
    ↓
setState({ isRegistered = true }) ✅
    ↓
Show SnackBar ✅
    ↓
❌ KHÔNG reload EventService.myRegisteredEvents
```

### **Vấn đề**:

`EventDetailScreen` **không** trigger reload danh sách `myRegisteredEvents` trong `EventService`.

Khi user quay lại "My Events" screen:
```dart
// MyEventsScreen.initState()
WidgetsBinding.instance.addPostFrameCallback((_) {
  context.read<EventService>().loadMyRegisteredEvents(); // ⚠️ Load từ cache cũ
});
```

Vì `EventService` đã load data trước đó và **chưa được refresh**, nên "My Events" vẫn hiển thị danh sách cũ (không có event vừa đăng ký).

---

## ✅ **Solution**

### **Add Provider Imports**

```dart
import 'package:provider/provider.dart';
import 'package:event_connect/features/event_management/domain/services/event_service.dart';
```

### **Update _handleRegister() Method**

**File**: `lib/features/event_management/presentation/screens/event_detail_screen.dart`

```dart
Future<void> _handleRegister() async {
  setState(() {
    isRegistering = true;
  });

  try {
    final accessToken = await _storage.read(key: 'auth_access');

    if (accessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập để đăng ký sự kiện')),
        );
      }
      setState(() {
        isRegistering = false;
      });
      return;
    }

    // Call register API
    final result = await _eventApi.registerForEvent(widget.event.id);

    if (result['status'] == 200 || result['status'] == 201) {
      setState(() {
        isRegistered = true;
        isRegistering = false;
      });

      // ✅ Reload EventService to update My Events list
      if (mounted) {
        context.read<EventService>().loadMyRegisteredEvents();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký sự kiện thành công!'),
            backgroundColor: Color(0xFF5669FF),
          ),
        );
      }
    } else {
      // ... error handling
    }
  } catch (e) {
    // ... exception handling
  }
}
```

---

## 📊 **Flow sau khi fix**:

```
EventDetailScreen._handleRegister()
    ↓
POST /api/events/{id}/register/ ✅
    ↓
setState({ isRegistered = true }) ✅
    ↓
context.read<EventService>().loadMyRegisteredEvents() ✅ NEW!
    ↓
    ├→ GET /api/registrations/my-events/
    ├→ Parse response
    ├→ Update EventService._myRegisteredEvents
    └→ notifyListeners()
    ↓
Show SnackBar ✅
```

Khi user quay lại "My Events":
```dart
// MyEventsScreen build()
final eventService = context.watch<EventService>();
final upcomingEvents = getUpcomingEvents(eventService); // ✅ Data mới đã có!
```

---

## 🧪 **Testing**

### **Before Fix** ❌:
1. Vào event detail
2. Click "Đăng ký"
3. Thấy SnackBar thành công
4. Quay lại "My Events" → **Không thấy sự kiện**
5. Phải kill app và restart mới thấy

### **After Fix** ✅:
1. Vào event detail
2. Click "Đăng ký"
3. Thấy SnackBar thành công
4. Quay lại "My Events" → **Thấy sự kiện ngay lập tức**

---

## 📝 **Technical Details**

### **EventService.loadMyRegisteredEvents()**

```dart
Future<void> loadMyRegisteredEvents() async {
  _setLoading(true);
  try {
    _myRegisteredEvents = await repository.getMyRegisteredEvents();
    _error = null;
  } catch (e) {
    _error = e.toString();
    _myRegisteredEvents = [];
  } finally {
    _setLoading(false);
  }
  // Triggers notifyListeners() internally via _setLoading()
}
```

### **MyEventsScreen listens to changes**

```dart
@override
Widget build(BuildContext context) {
  final eventService = context.watch<EventService>(); // ✅ Rebuilds when EventService changes
  final upcomingEvents = getUpcomingEvents(eventService);
  // ...
}
```

**Flow**:
1. `context.read<EventService>()` → Get EventService instance
2. `.loadMyRegisteredEvents()` → Fetch new data
3. `notifyListeners()` → Notify all listeners
4. `context.watch<EventService>()` → Rebuild MyEventsScreen
5. Display updated list

---

## 🚀 **Alternative Solutions Considered**

### **Option 1: Use EventService.registerForEvent()** ⭐ (Recommended for future)

Thay vì gọi `_eventApi.registerForEvent()` directly, nên dùng:

```dart
final eventService = context.read<EventService>();
final success = await eventService.registerForEvent(widget.event.id);

if (success) {
  // EventService đã tự động reload myRegisteredEvents
  setState(() {
    isRegistered = true;
    isRegistering = false;
  });
  // ... show snackbar
}
```

**Advantages**:
- Centralized logic
- Automatic refresh
- Better error handling
- Consistent state management

### **Option 2: Manual refresh on MyEventsScreen mount**

Luôn refresh khi vào MyEventsScreen:

```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 3, vsync: this);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<EventService>().loadMyRegisteredEvents(); // Always refresh
  });
}
```

**Disadvantages**:
- Unnecessary API calls
- Slower UX
- Doesn't solve root cause

---

## 🔮 **Future Enhancements**

### **1. Add Unregister Feature**

Hiện tại chỉ có button "Đăng ký", không có "Hủy đăng ký".

**Suggested UI**:
```dart
isRegistered
  ? Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _handleUnregister,
            child: Text('Hủy đăng ký'),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleCheckIn,
            child: Text('Check-in'),
          ),
        ),
      ],
    )
  : ElevatedButton(
      onPressed: _handleRegister,
      child: Text('Đăng ký'),
    )
```

**Implementation**:
```dart
Future<void> _handleUnregister() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Xác nhận hủy đăng ký'),
      content: Text('Bạn có chắc muốn hủy đăng ký sự kiện này?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Không'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Hủy đăng ký'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  setState(() => isRegistering = true);

  final result = await _eventApi.unregisterFromEvent(widget.event.id);

  if (result['status'] == 200) {
    setState(() {
      isRegistered = false;
      isRegistering = false;
    });

    if (mounted) {
      context.read<EventService>().loadMyRegisteredEvents(); // ✅ Reload
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hủy đăng ký thành công')),
      );
    }
  } else {
    setState(() => isRegistering = false);
    // ... error handling
  }
}
```

### **2. Optimistic Updates**

Cập nhật UI ngay lập tức, không cần đợi API:

```dart
// Immediately update local state
setState(() {
  isRegistered = true;
  isRegistering = false;
});

// Add to EventService immediately
context.read<EventService>().addRegisteredEventLocally(widget.event);

// Then sync with backend
final result = await _eventApi.registerForEvent(widget.event.id);

if (result['status'] != 200 && result['status'] != 201) {
  // Rollback on error
  setState(() => isRegistered = false);
  context.read<EventService>().removeRegisteredEventLocally(widget.event);
  // ... show error
}
```

### **3. Real-time Sync**

Use WebSocket hoặc polling để auto-sync:

```dart
// In EventService
Timer? _syncTimer;

void startAutoSync() {
  _syncTimer = Timer.periodic(Duration(seconds: 30), (_) {
    loadMyRegisteredEvents();
  });
}

void stopAutoSync() {
  _syncTimer?.cancel();
}
```

---

## ✅ **Status**

**FIXED** ✅

Sau khi đăng ký sự kiện, danh sách "My Events" sẽ được reload tự động và hiển thị sự kiện vừa đăng ký.
