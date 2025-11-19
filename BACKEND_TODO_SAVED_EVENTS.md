# 📋 BACKEND TODO - Saved Events Feature

## 🎯 Overview
Cần implement tính năng "Lưu sự kiện" (Saved Events / Bookmarks) để user có thể lưu các sự kiện yêu thích và xem lại sau.

---

## 🗄️ Database Schema

### 1. Tạo Model `SavedEvent`

**File:** `event_connect_backend/event_management/models.py`

```python
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class SavedEvent(models.Model):
    """
    Model để lưu các sự kiện mà user đã bookmark
    """
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='saved_events',
        verbose_name='User'
    )
    event = models.ForeignKey(
        'Event', 
        on_delete=models.CASCADE, 
        related_name='saved_by_users',
        verbose_name='Event'
    )
    saved_at = models.DateTimeField(auto_now_add=True, verbose_name='Saved At')
    
    class Meta:
        db_table = 'saved_events'
        verbose_name = 'Saved Event'
        verbose_name_plural = 'Saved Events'
        ordering = ['-saved_at']
        # Một user chỉ có thể save một event một lần
        unique_together = [['user', 'event']]
        indexes = [
            models.Index(fields=['user', '-saved_at']),
            models.Index(fields=['event']),
        ]
    
    def __str__(self):
        return f"{self.user.email} saved {self.event.title}"
```

### 2. Migration

```bash
cd event_connect_backend
python manage.py makemigrations event_management
python manage.py migrate
```

---

## 🔧 API Endpoints

### 1️⃣ Lấy danh sách sự kiện đã lưu

**GET** `/api/events/saved/`

**Description:** Lấy danh sách các sự kiện mà user hiện tại đã save

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
      "description": "Cuộc thi lập trình...",
      "club": {
        "id": 2,
        "name": "CLB Lập trình",
        "slug": "clb-lap-trinh"
      },
      "start_at": "2025-12-01T09:00:00Z",
      "end_at": "2025-12-01T17:00:00Z",
      "location": "Hội trường A",
      "image_url": "https://example.com/poster.jpg",
      "capacity": 100,
      "participant_count": 45,
      "status": "approved",
      "is_registered": true,
      "is_saved": true,
      "saved_at": "2025-11-15T10:30:00Z"
    }
  ]
}
```

**Response 401:**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

### 2️⃣ Lưu sự kiện (Bookmark)

**POST** `/api/events/{event_id}/save/`

**Description:** Lưu một sự kiện vào danh sách yêu thích

**Authentication:** Required (Bearer Token)

**Path Parameters:**
- `event_id` (int, required): ID của sự kiện cần save

**Request Body:** None (empty)

**Response 201:**
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

**Response 404:**
```json
{
  "detail": "Not found."
}
```

---

### 3️⃣ Bỏ lưu sự kiện (Unsave/Remove bookmark)

**POST** `/api/events/{event_id}/unsave/`

hoặc

**DELETE** `/api/events/{event_id}/save/`

**Description:** Xóa sự kiện khỏi danh sách yêu thích

**Authentication:** Required (Bearer Token)

**Path Parameters:**
- `event_id` (int, required): ID của sự kiện cần unsave

**Request Body:** None (empty)

**Response 200:**
```json
{
  "message": "Event unsaved successfully",
  "event_id": 5
}
```

**Response 404 (Not saved):**
```json
{
  "error": "Event not saved"
}
```

---

### 4️⃣ Kiểm tra sự kiện đã được lưu chưa

**GET** `/api/events/{event_id}/is-saved/`

**Description:** Kiểm tra xem user hiện tại đã save event này chưa

**Authentication:** Required (Bearer Token)

**Path Parameters:**
- `event_id` (int, required): ID của sự kiện

**Response 200:**
```json
{
  "event_id": 5,
  "is_saved": true,
  "saved_at": "2025-11-15T10:30:00Z"
}
```

hoặc

```json
{
  "event_id": 5,
  "is_saved": false,
  "saved_at": null
}
```

---

## 📝 Serializer

**File:** `event_connect_backend/event_management/serializers.py`

```python
from rest_framework import serializers
from .models import SavedEvent, Event

class SavedEventSerializer(serializers.ModelSerializer):
    event = EventListSerializer(read_only=True)
    
    class Meta:
        model = SavedEvent
        fields = ['id', 'event', 'saved_at']
        read_only_fields = ['id', 'saved_at']


class SavedEventActionSerializer(serializers.Serializer):
    """Serializer cho save/unsave actions"""
    # Không cần field nào, chỉ validate event existence
    pass
```

---

## 🎨 ViewSet Implementation

**File:** `event_connect_backend/event_management/views.py`

```python
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from .models import SavedEvent

class EventViewSet(viewsets.ModelViewSet):
    # ... existing code ...
    
    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def saved(self, request):
        """Get user's saved events"""
        saved_events = SavedEvent.objects.filter(
            user=request.user
        ).select_related('event', 'event__club').order_by('-saved_at')
        
        # Pagination
        page = self.paginate_queryset(saved_events)
        if page is not None:
            # Extract events from SavedEvent
            events = [se.event for se in page]
            serializer = EventListSerializer(events, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
        
        events = [se.event for se in saved_events]
        serializer = EventListSerializer(events, many=True, context={'request': request})
        return Response({'results': serializer.data})
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def save(self, request, pk=None):
        """Save an event"""
        event = self.get_object()
        
        # Check if already saved
        if SavedEvent.objects.filter(user=request.user, event=event).exists():
            return Response(
                {'error': 'Event already saved'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create saved event
        saved_event = SavedEvent.objects.create(
            user=request.user,
            event=event
        )
        
        return Response({
            'message': 'Event saved successfully',
            'event_id': event.id,
            'saved_at': saved_event.saved_at
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post', 'delete'], permission_classes=[permissions.IsAuthenticated])
    def unsave(self, request, pk=None):
        """Unsave an event"""
        event = self.get_object()
        
        try:
            saved_event = SavedEvent.objects.get(user=request.user, event=event)
            saved_event.delete()
            
            return Response({
                'message': 'Event unsaved successfully',
                'event_id': event.id
            })
        except SavedEvent.DoesNotExist:
            return Response(
                {'error': 'Event not saved'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=True, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def is_saved(self, request, pk=None):
        """Check if event is saved"""
        event = self.get_object()
        
        try:
            saved_event = SavedEvent.objects.get(user=request.user, event=event)
            return Response({
                'event_id': event.id,
                'is_saved': True,
                'saved_at': saved_event.saved_at
            })
        except SavedEvent.DoesNotExist:
            return Response({
                'event_id': event.id,
                'is_saved': False,
                'saved_at': None
            })
```

---

## 🔄 Update EventSerializer

Thêm field `is_saved` vào EventListSerializer và EventDetailSerializer:

```python
class EventListSerializer(serializers.ModelSerializer):
    # ... existing fields ...
    is_saved = serializers.SerializerMethodField()
    
    def get_is_saved(self, obj):
        """Check if current user has saved this event"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return SavedEvent.objects.filter(
                user=request.user,
                event=obj
            ).exists()
        return False
    
    class Meta:
        model = Event
        fields = [
            # ... existing fields ...
            'is_saved',
        ]
```

---

## 🧪 Testing với cURL

### 1. Lưu sự kiện
```bash
curl -X POST http://127.0.0.1:8000/api/events/5/save/ \
  -H "Authorization: Bearer <access_token>"
```

### 2. Lấy danh sách đã lưu
```bash
curl -X GET http://127.0.0.1:8000/api/events/saved/ \
  -H "Authorization: Bearer <access_token>"
```

### 3. Bỏ lưu sự kiện
```bash
curl -X POST http://127.0.0.1:8000/api/events/5/unsave/ \
  -H "Authorization: Bearer <access_token>"
```

### 4. Kiểm tra đã lưu chưa
```bash
curl -X GET http://127.0.0.1:8000/api/events/5/is-saved/ \
  -H "Authorization: Bearer <access_token>"
```

---

## 📊 Database Indexes (Performance)

```python
# Trong SavedEvent model
class Meta:
    indexes = [
        models.Index(fields=['user', '-saved_at']),  # Query saved events by user
        models.Index(fields=['event']),               # Count how many users saved an event
    ]
```

---

## 🔐 Permissions

- Tất cả endpoints yêu cầu authentication (Bearer Token)
- User chỉ có thể:
  - Xem danh sách sự kiện mình đã save
  - Save/unsave sự kiện của chính mình
  - Không thể xem danh sách saved events của user khác

---

## 📈 Optional: Statistics

Có thể thêm field `saved_count` vào Event model để track số lượng saves:

```python
# Trong Event model
saved_count = models.IntegerField(default=0, verbose_name='Saved Count')

# Trong EventViewSet.save()
event.saved_count += 1
event.save(update_fields=['saved_count'])

# Trong EventViewSet.unsave()
event.saved_count = max(0, event.saved_count - 1)
event.save(update_fields=['saved_count'])
```

---

## ✅ Checklist cho Backend Team

- [ ] Tạo model `SavedEvent` với unique constraint
- [ ] Run migrations (`makemigrations` + `migrate`)
- [ ] Implement 4 endpoints trong EventViewSet:
  - [ ] `GET /api/events/saved/` - List saved events
  - [ ] `POST /api/events/{id}/save/` - Save event
  - [ ] `POST /api/events/{id}/unsave/` - Unsave event
  - [ ] `GET /api/events/{id}/is-saved/` - Check if saved
- [ ] Update EventListSerializer/EventDetailSerializer thêm field `is_saved`
- [ ] Add indexes cho performance
- [ ] Test với cURL/Postman
- [ ] Update API documentation

---

## 🚀 Priority: **HIGH**

Feature này cần thiết cho UX tốt. User cần lưu sự kiện để xem lại sau.

---

## 📞 Contact

Nếu có câu hỏi về requirements, liên hệ Frontend Team!
