# 📋 API LƯU SỰ KIỆN (SAVED EVENTS / BOOKMARKS)

## 🎯 Overview
API cho tính năng "Lưu sự kiện yêu thích" - cho phép user bookmark các sự kiện để xem lại sau.

---

## 🔑 Xác thực
- **Required**: User phải đăng nhập (Bearer Token)
- **Header**: `Authorization: Bearer <access_token>`
- **Permission**: Tất cả user đã đăng nhập đều có thể sử dụng

---

## 1️⃣ Lấy danh sách sự kiện đã lưu

### **GET** `/api/events/saved/`

**Description:** Lấy danh sách các sự kiện mà user hiện tại đã save/bookmark

**Authentication:** Required (Bearer Token)

**Query Parameters:**
- `page` (int, optional): Số trang (default: 1)
- `page_size` (int, optional): Số items per page (default: 10, max: 100)

**Response 200:**
```json
{
  "count": 25,
  "next": "http://127.0.0.1:8000/api/events/saved/?page=2",
  "previous": null,
  "results": [
    {
      "id": 5,
      "title": "Hackathon 2025",
      "slug": "hackathon-2025",
      "description": "Cuộc thi lập trình...",
      "category": "technology",
      "club": {
        "id": 2,
        "name": "CLB Lập trình",
        "slug": "clb-lap-trinh"
      },
      "location": "Hội trường A",
      "start_at": "2025-12-01T09:00:00Z",
      "end_at": "2025-12-01T17:00:00Z",
      "registration_start": "2025-11-20T00:00:00Z",
      "registration_end": "2025-11-30T23:59:59Z",
      "capacity": 100,
      "registration_count": 45,
      "checked_in_count": 0,
      "attended_count": 0,
      "total_participants": 45,
      "is_full": false,
      "is_registration_open": true,
      "poster": "http://127.0.0.1:8000/media/events/posters/hackathon.jpg",
      "status": "approved",
      "is_featured": true,
      "view_count": 250,
      "average_rating": 4.5,
      "rating_count": 20,
      "created_at": "2025-11-10T10:00:00Z",
      "is_saved": true,
      "saved_at": "2025-11-15T10:30:00Z"
    },
    {
      "id": 8,
      "title": "Music Festival 2025",
      "slug": "music-festival-2025",
      "description": "Đêm nhạc sôi động...",
      "category": "entertainment",
      "club": {
        "id": 3,
        "name": "CLB Âm nhạc",
        "slug": "clb-am-nhac"
      },
      "location": "Sân khấu ngoài trời",
      "start_at": "2025-12-15T18:00:00Z",
      "end_at": "2025-12-15T22:00:00Z",
      "capacity": 500,
      "registration_count": 380,
      "is_full": false,
      "is_registration_open": true,
      "poster": "http://127.0.0.1:8000/media/events/posters/music-fest.jpg",
      "status": "approved",
      "is_featured": false,
      "view_count": 450,
      "average_rating": 4.8,
      "rating_count": 35,
      "created_at": "2025-11-12T14:00:00Z",
      "is_saved": true,
      "saved_at": "2025-11-16T08:15:00Z"
    }
  ]
}
```

**Response 401 (Unauthorized):**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

**Lưu ý:**
- Sự kiện được sắp xếp theo thời gian lưu (mới nhất → cũ nhất)
- Field `is_saved` luôn = `true` trong endpoint này
- Field `saved_at` cho biết thời gian user đã save sự kiện

---

## 2️⃣ Lưu sự kiện (Bookmark)

### **POST** `/api/events/{event_id}/save/`

**Description:** Lưu một sự kiện vào danh sách yêu thích của user

**Authentication:** Required (Bearer Token)

**Path Parameters:**
- `event_id` (int, required): ID của sự kiện cần save

**Request Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:** None (empty)

**Response 201 (Created):**
```json
{
  "message": "Event saved successfully",
  "event_id": 5,
  "saved_at": "2025-11-18T10:30:00Z"
}
```

**Response 400 (Already saved):**
```json
{
  "error": "Event already saved"
}
```

**Response 401 (Unauthorized):**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

**Response 404 (Event not found):**
```json
{
  "detail": "Not found."
}
```

---

## 3️⃣ Bỏ lưu sự kiện (Unsave/Remove bookmark)

### **POST** `/api/events/{event_id}/unsave/`

hoặc

### **DELETE** `/api/events/{event_id}/unsave/`

**Description:** Xóa sự kiện khỏi danh sách yêu thích

**Authentication:** Required (Bearer Token)

**Path Parameters:**
- `event_id` (int, required): ID của sự kiện cần unsave

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:** None (empty)

**Response 200:**
```json
{
  "message": "Event unsaved successfully",
  "event_id": 5
}
```

**Response 404 (Event not saved):**
```json
{
  "error": "Event not saved"
}
```

**Response 401 (Unauthorized):**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

## 4️⃣ Kiểm tra sự kiện đã được lưu chưa

### **GET** `/api/events/{event_id}/is-saved/`

**Description:** Kiểm tra xem user hiện tại đã save event này chưa

**Authentication:** Required (Bearer Token)

**Path Parameters:**
- `event_id` (int, required): ID của sự kiện

**Response 200 (Đã lưu):**
```json
{
  "event_id": 5,
  "is_saved": true,
  "saved_at": "2025-11-15T10:30:00Z"
}
```

**Response 200 (Chưa lưu):**
```json
{
  "event_id": 5,
  "is_saved": false,
  "saved_at": null
}
```

**Response 401 (Unauthorized):**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

**Response 404 (Event not found):**
```json
{
  "detail": "Not found."
}
```

---

## 🔄 Field `is_saved` trong EventListSerializer

Tất cả endpoints trả về danh sách events (như `/api/events/`) giờ đã có thêm field `is_saved`:

### **GET** `/api/events/`

```json
{
  "count": 50,
  "results": [
    {
      "id": 5,
      "title": "Hackathon 2025",
      "is_saved": true,  // ⭐️ New field!
      // ... other fields
    },
    {
      "id": 6,
      "title": "Workshop AI",
      "is_saved": false,  // ⭐️ New field!
      // ... other fields
    }
  ]
}
```

**Logic:**
- Nếu user đã login: `is_saved` = true/false dựa trên database
- Nếu user chưa login: `is_saved` = false

---

## 🎯 Use Case Frontend

### 1. Màn hình danh sách sự kiện

```typescript
// Component: EventCard

interface Event {
  id: number;
  title: string;
  is_saved: boolean;
  // ... other fields
}

const EventCard = ({ event }: { event: Event }) => {
  const [isSaved, setIsSaved] = useState(event.is_saved);
  
  const handleSaveToggle = async () => {
    if (isSaved) {
      // Unsave
      await unsaveEvent(event.id);
      setIsSaved(false);
    } else {
      // Save
      await saveEvent(event.id);
      setIsSaved(true);
    }
  };
  
  return (
    <div className="event-card">
      <h3>{event.title}</h3>
      <button onClick={handleSaveToggle}>
        {isSaved ? '❤️ Đã lưu' : '🤍 Lưu'}
      </button>
    </div>
  );
};

// API functions
const saveEvent = async (eventId: number) => {
  const response = await fetch(`/api/events/${eventId}/save/`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
    },
  });
  
  if (!response.ok) {
    throw new Error('Failed to save event');
  }
  
  return response.json();
};

const unsaveEvent = async (eventId: number) => {
  const response = await fetch(`/api/events/${eventId}/unsave/`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
    },
  });
  
  if (!response.ok) {
    throw new Error('Failed to unsave event');
  }
  
  return response.json();
};
```

### 2. Màn hình "Sự kiện đã lưu"

```typescript
// Component: SavedEventsScreen

const SavedEventsScreen = () => {
  const [savedEvents, setSavedEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    fetchSavedEvents();
  }, []);
  
  const fetchSavedEvents = async () => {
    try {
      const response = await fetch('/api/events/saved/', {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
        },
      });
      
      const data = await response.json();
      setSavedEvents(data.results);
    } catch (error) {
      console.error('Error fetching saved events:', error);
    } finally {
      setLoading(false);
    }
  };
  
  const handleUnsave = async (eventId: number) => {
    try {
      await fetch(`/api/events/${eventId}/unsave/`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
        },
      });
      
      // Remove from list
      setSavedEvents(prev => prev.filter(e => e.id !== eventId));
    } catch (error) {
      console.error('Error unsaving event:', error);
    }
  };
  
  if (loading) return <Spinner />;
  
  return (
    <div>
      <h1>Sự kiện đã lưu ({savedEvents.length})</h1>
      {savedEvents.length === 0 ? (
        <p>Chưa có sự kiện nào được lưu</p>
      ) : (
        savedEvents.map(event => (
          <EventCard 
            key={event.id} 
            event={event}
            onUnsave={() => handleUnsave(event.id)}
          />
        ))
      )}
    </div>
  );
};
```

### 3. Flutter Example

```dart
// Service: SavedEventService

class SavedEventService {
  final String baseUrl = 'http://127.0.0.1:8000/api';
  
  Future<List<Event>> getSavedEvents({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/saved/?page=$page'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Event.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load saved events');
    }
  }
  
  Future<void> saveEvent(int eventId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/$eventId/save/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    if (response.statusCode == 201) {
      print('Event saved successfully');
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    } else {
      throw Exception('Failed to save event');
    }
  }
  
  Future<void> unsaveEvent(int eventId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/$eventId/unsave/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    if (response.statusCode == 200) {
      print('Event unsaved successfully');
    } else if (response.statusCode == 404) {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    } else {
      throw Exception('Failed to unsave event');
    }
  }
  
  Future<bool> isEventSaved(int eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$eventId/is-saved/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['is_saved'] as bool;
    } else {
      throw Exception('Failed to check saved status');
    }
  }
}

// Widget: SavedEventsScreen
class SavedEventsScreen extends StatefulWidget {
  @override
  _SavedEventsScreenState createState() => _SavedEventsScreenState();
}

class _SavedEventsScreenState extends State<SavedEventsScreen> {
  final SavedEventService _service = SavedEventService();
  List<Event> _savedEvents = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSavedEvents();
  }
  
  Future<void> _loadSavedEvents() async {
    try {
      final events = await _service.getSavedEvents();
      setState(() {
        _savedEvents = events;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  Future<void> _handleUnsave(Event event) async {
    try {
      await _service.unsaveEvent(event.id);
      
      setState(() {
        _savedEvents.removeWhere((e) => e.id == event.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã bỏ lưu sự kiện')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_savedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Chưa có sự kiện nào được lưu'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _savedEvents.length,
      itemBuilder: (context, index) {
        final event = _savedEvents[index];
        
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: event.poster != null
                ? Image.network(event.poster!, width: 60, fit: BoxFit.cover)
                : Icon(Icons.event),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 ${event.location}'),
                Text('📅 ${event.startAt}'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.bookmark, color: Colors.red),
              onPressed: () => _handleUnsave(event),
            ),
            onTap: () {
              // Navigate to event detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(eventId: event.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Widget: SaveButton (reusable)
class SaveButton extends StatefulWidget {
  final Event event;
  
  SaveButton({required this.event});
  
  @override
  _SaveButtonState createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  late bool _isSaved;
  bool _loading = false;
  
  @override
  void initState() {
    super.initState();
    _isSaved = widget.event.isSaved;
  }
  
  Future<void> _toggleSave() async {
    setState(() => _loading = true);
    
    try {
      final service = SavedEventService();
      
      if (_isSaved) {
        await service.unsaveEvent(widget.event.id);
      } else {
        await service.saveEvent(widget.event.id);
      }
      
      setState(() {
        _isSaved = !_isSaved;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? Colors.red : Colors.grey,
            ),
      onPressed: _loading ? null : _toggleSave,
    );
  }
}
```

---

## 🔒 Quyền truy cập

| Endpoint | Method | Permission Required | Mô tả |
|----------|--------|---------------------|-------|
| `/api/events/saved/` | GET | Authenticated User | Xem sự kiện đã lưu |
| `/api/events/{id}/save/` | POST | Authenticated User | Lưu sự kiện |
| `/api/events/{id}/unsave/` | POST/DELETE | Authenticated User | Bỏ lưu sự kiện |
| `/api/events/{id}/is-saved/` | GET | Authenticated User | Kiểm tra đã lưu |

**Lưu ý:**
- User chỉ thấy/quản lý sự kiện mà chính họ đã save
- Không thể xem danh sách saved events của user khác
- Một user chỉ có thể save một event một lần (unique constraint)

---

## ✅ Testing với cURL

### 1. Login để lấy token
```bash
curl -X POST http://127.0.0.1:8000/api/accounts/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@example.com",
    "password": "password123"
  }'

# Response:
# {
#   "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#   "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
# }
```

### 2. Lưu sự kiện
```bash
curl -X POST http://127.0.0.1:8000/api/events/5/save/ \
  -H "Authorization: Bearer <access_token>"
```

### 3. Lấy danh sách đã lưu
```bash
curl -X GET http://127.0.0.1:8000/api/events/saved/ \
  -H "Authorization: Bearer <access_token>"
```

### 4. Bỏ lưu sự kiện
```bash
curl -X POST http://127.0.0.1:8000/api/events/5/unsave/ \
  -H "Authorization: Bearer <access_token>"
```

### 5. Kiểm tra đã lưu chưa
```bash
curl -X GET http://127.0.0.1:8000/api/events/5/is-saved/ \
  -H "Authorization: Bearer <access_token>"
```

---

## 📊 Database Schema

### Bảng `saved_events`

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary Key |
| user_id | INTEGER | Foreign Key → users.id |
| event_id | INTEGER | Foreign Key → events.id |
| saved_at | DATETIME | Thời gian lưu |

**Constraints:**
- `UNIQUE(user_id, event_id)` - Một user chỉ save một event một lần
- Index on `(user_id, saved_at DESC)` - Query saved events nhanh
- Index on `event_id` - Count số lượng saves

---

## 🎨 UI/UX Recommendations

### Icon Save Button:
- ❤️ / 🤍 - Heart icon (filled = saved, outline = not saved)
- 🔖 / 📑 - Bookmark icon
- ⭐️ / ☆ - Star icon

### Animation:
- Smooth transition khi click save/unsave
- Loading spinner trong khi API call
- Toast/Snackbar notification sau khi save thành công

### Empty State:
Khi chưa có saved events:
```
┌────────────────────────────────┐
│                                │
│         📑                     │
│                                │
│   Chưa có sự kiện nào được lưu │
│                                │
│   Nhấn vào ❤️ để lưu sự kiện  │
│   yêu thích của bạn!           │
│                                │
└────────────────────────────────┘
```

---

## 🐛 Error Handling

### Common Errors:

1. **401 Unauthorized:**
   - Token hết hạn hoặc không hợp lệ
   - Action: Redirect to login

2. **400 Bad Request (Save):**
   - Event đã được save rồi
   - Action: Update UI state, show message "Đã lưu trước đó"

3. **404 Not Found (Unsave):**
   - Event chưa được save
   - Action: Update UI state to "not saved"

4. **404 Not Found (Event):**
   - Event ID không tồn tại
   - Action: Show error "Sự kiện không tồn tại"

---

## 📈 Optional Features (Future)

### 1. Saved Count cho Event:
```python
# Thêm vào Event model
saved_count = models.IntegerField(default=0)

# Update khi save/unsave
event.saved_count += 1  # or -= 1
event.save()
```

### 2. Notification khi sự kiện đã lưu sắp diễn ra:
```python
# Cron job hoặc Celery task
from datetime import timedelta

events = Event.objects.filter(
    start_at__gte=now(),
    start_at__lte=now() + timedelta(days=1)
)

for event in events:
    users = SavedEvent.objects.filter(event=event).values_list('user', flat=True)
    # Send notification to users
```

### 3. Thống kê Saved Events:
```python
# Top saved events
Event.objects.annotate(
    save_count=Count('saved_by_users')
).order_by('-save_count')[:10]
```

---

## 📱 Base URL

**Development:** `http://127.0.0.1:8000/api`  
**Production:** `https://your-domain.com/api`

---

## 🚀 Quick Start

1. **Save một sự kiện:**
   ```
   POST /api/events/5/save/
   Header: Authorization: Bearer <token>
   ```

2. **Xem danh sách đã lưu:**
   ```
   GET /api/events/saved/
   Header: Authorization: Bearer <token>
   ```

3. **Bỏ lưu:**
   ```
   POST /api/events/5/unsave/
   Header: Authorization: Bearer <token>
   ```

---

## ✅ Checklist Implementation

Backend (✅ Completed):
- ✅ Model `SavedEvent` với unique constraint
- ✅ Migration đã chạy thành công
- ✅ 4 API endpoints:
  - ✅ `GET /api/events/saved/`
  - ✅ `POST /api/events/{id}/save/`
  - ✅ `POST /api/events/{id}/unsave/`
  - ✅ `GET /api/events/{id}/is-saved/`
- ✅ Update `EventListSerializer` thêm field `is_saved`
- ✅ Database indexes cho performance
- ✅ Admin panel registration
- ✅ API documentation

Frontend (TODO):
- [ ] UI cho save button trên event card
- [ ] Màn hình "Saved Events"
- [ ] Empty state design
- [ ] Animation khi save/unsave
- [ ] Error handling

---

## 📞 Support

Nếu có câu hỏi về API, liên hệ Backend Team! 🎉

**Feature Status:** ✅ **COMPLETED** - Ready for Frontend Integration!
