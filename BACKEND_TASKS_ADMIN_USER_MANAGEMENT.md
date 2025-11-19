# Backend Tasks - Admin User Management API

## 📋 Overview
Frontend đã implement đầy đủ Admin Dashboard với User Management UI. Backend cần implement các API endpoints còn thiếu để hỗ trợ các chức năng quản lý user.

---

## ✅ APIs đã có (hoạt động tốt)

### 1. Get Users List
```
GET /api/admin/users/
```
**Query params:**
- `role` (optional): Filter by role
- `search` (optional): Search username/email/name
- `page_size` (optional): Items per page (default: 20)
- `page` (optional): Page number (default: 1)

**Response:**
```json
{
  "count": 100,
  "results": [
    {
      "id": 1,
      "username": "student001",
      "email": "student@example.com",
      "full_name": "Nguyen Van A",
      "role": "student",
      "student_id": "SV001",
      "faculty": "CNTT",
      "is_active": true,
      "event_registrations_count": 5,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

**Location:** `event_connect_backend/notifications/views.py` (line 198)

---

## ❌ APIs cần implement

### 1. Get User Detail
```
GET /api/admin/users/{id}/
```

**Response:**
```json
{
  "id": 1,
  "username": "student001",
  "email": "student@example.com",
  "full_name": "Nguyen Van A",
  "first_name": "Van A",
  "last_name": "Nguyen",
  "role": "student",
  "student_id": "SV001",
  "faculty": "CNTT",
  "is_active": true,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Permission:** System Admin only

---

### 2. Update User Info
```
PATCH /api/admin/users/{id}/
```

**Request body:**
```json
{
  "first_name": "Van B",
  "last_name": "Nguyen",
  "email": "newmail@example.com",
  "role": "club_admin",
  "faculty": "Kinh tế"
}
```

**Response:**
```json
{
  "id": 1,
  "username": "student001",
  "email": "newmail@example.com",
  "full_name": "Nguyen Van B",
  "role": "club_admin",
  "faculty": "Kinh tế",
  "is_active": true,
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Permission:** System Admin only

**Notes:**
- Không cho phép thay đổi `username`
- Validate email format
- Validate role (student, club_admin, system_admin)

---

### 3. Activate User
```
POST /api/admin/users/{id}/activate/
```

**Request body:** Empty or `{}`

**Response:**
```json
{
  "success": true,
  "message": "User activated successfully",
  "user": {
    "id": 1,
    "username": "student001",
    "is_active": true
  }
}
```

**Permission:** System Admin only

**Logic:**
- Set `is_active = True`
- Tạo activity log (optional)
- Return 400 nếu user đã active

---

### 4. Deactivate User
```
POST /api/admin/users/{id}/deactivate/
```

**Request body:** Empty or `{}`

**Response:**
```json
{
  "success": true,
  "message": "User deactivated successfully",
  "user": {
    "id": 1,
    "username": "student001",
    "is_active": false
  }
}
```

**Permission:** System Admin only

**Logic:**
- Set `is_active = False`
- User không thể login khi `is_active = False`
- Tạo activity log (optional)
- Return 400 nếu user đã inactive

---

### 5. Delete User (Soft Delete khuyến nghị)
```
DELETE /api/admin/users/{id}/
```

**Response:**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

**Permission:** System Admin only

**Logic:**
- **Khuyến nghị:** Soft delete (set `is_active = False` + `deleted_at = now()`)
- Hoặc: Hard delete (xóa vĩnh viễn khỏi DB)
- Không cho phép xóa chính mình (current logged-in admin)
- Handle foreign key constraints:
  - Event registrations → set user = null hoặc cascade
  - Created events → set created_by = null
  - Notifications → set user = null hoặc cascade

---

## 🔐 Permissions

Tất cả endpoints trên yêu cầu:
```python
@permission_classes([IsSystemAdmin])
```

**IsSystemAdmin permission class:**
```python
class IsSystemAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'system_admin'
```

---

## 📁 Suggested Implementation

### Location
`event_connect_backend/accounts/views.py` (hoặc tạo `admin_views.py`)

### Approach 1: ViewSet (Khuyến nghị)
```python
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status

class UserManagementViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsSystemAdmin]
    
    def get_queryset(self):
        queryset = User.objects.all()
        role = self.request.query_params.get('role')
        search = self.request.query_params.get('search')
        
        if role:
            queryset = queryset.filter(role=role)
        if search:
            queryset = queryset.filter(
                Q(username__icontains=search) |
                Q(email__icontains=search) |
                Q(first_name__icontains=search) |
                Q(last_name__icontains=search)
            )
        return queryset.order_by('-created_at')
    
    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        user = self.get_object()
        if user.is_active:
            return Response(
                {'error': 'User is already active'},
                status=status.HTTP_400_BAD_REQUEST
            )
        user.is_active = True
        user.save()
        return Response({
            'success': True,
            'message': 'User activated successfully',
            'user': {'id': user.id, 'username': user.username, 'is_active': user.is_active}
        })
    
    @action(detail=True, methods=['post'])
    def deactivate(self, request, pk=None):
        user = self.get_object()
        if not user.is_active:
            return Response(
                {'error': 'User is already inactive'},
                status=status.HTTP_400_BAD_REQUEST
            )
        user.is_active = False
        user.save()
        return Response({
            'success': True,
            'message': 'User deactivated successfully',
            'user': {'id': user.id, 'username': user.username, 'is_active': user.is_active}
        })
    
    def destroy(self, request, pk=None):
        user = self.get_object()
        if user.id == request.user.id:
            return Response(
                {'error': 'Cannot delete yourself'},
                status=status.HTTP_400_BAD_REQUEST
            )
        # Soft delete
        user.is_active = False
        user.save()
        # Or hard delete:
        # user.delete()
        return Response({'success': True, 'message': 'User deleted successfully'})
```

### URL Configuration
**In `accounts/urls.py`:**
```python
from rest_framework.routers import DefaultRouter
from .views import UserManagementViewSet

router = DefaultRouter()
router.register(r'admin/users', UserManagementViewSet, basename='admin-users')

urlpatterns = [
    # ... existing paths
    path('', include(router.urls)),
]
```

**Result URLs:**
```
GET    /api/admin/users/              # List users
GET    /api/admin/users/{id}/         # Get user detail
PATCH  /api/admin/users/{id}/         # Update user
DELETE /api/admin/users/{id}/         # Delete user
POST   /api/admin/users/{id}/activate/   # Activate user
POST   /api/admin/users/{id}/deactivate/ # Deactivate user
```

---

## 🧪 Testing

### Manual Testing với curl/Postman

**1. Get users:**
```bash
curl -H "Authorization: Bearer <token>" http://localhost:8000/api/admin/users/
```

**2. Activate user:**
```bash
curl -X POST -H "Authorization: Bearer <token>" http://localhost:8000/api/admin/users/1/activate/
```

**3. Update user:**
```bash
curl -X PATCH \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"first_name": "New Name", "role": "club_admin"}' \
  http://localhost:8000/api/admin/users/1/
```

**4. Delete user:**
```bash
curl -X DELETE -H "Authorization: Bearer <token>" http://localhost:8000/api/admin/users/1/
```

---

## ✅ Checklist

Backend team cần hoàn thành:

- [ ] Tạo `UserManagementViewSet` trong `accounts/views.py` hoặc `accounts/admin_views.py`
- [ ] Implement `IsSystemAdmin` permission class
- [ ] Tạo/update `UserSerializer` với các fields cần thiết
- [ ] Register router trong `accounts/urls.py`
- [ ] Test GET `/api/admin/users/{id}/` - Get user detail
- [ ] Test PATCH `/api/admin/users/{id}/` - Update user
- [ ] Test POST `/api/admin/users/{id}/activate/` - Activate user
- [ ] Test POST `/api/admin/users/{id}/deactivate/` - Deactivate user
- [ ] Test DELETE `/api/admin/users/{id}/` - Delete user
- [ ] Handle edge cases:
  - [ ] Cannot deactivate yourself
  - [ ] Cannot delete yourself
  - [ ] Validate role changes
  - [ ] Handle foreign key constraints on delete
- [ ] Add activity logging (optional)
- [ ] Update API documentation

---

## 📝 Notes

1. **Frontend đã sẵn sàng** - Ngay khi backend implement xong, frontend sẽ hoạt động ngay lập tức.

2. **Authenticated Dio** - Frontend đã setup Dio với TokenInterceptor, tất cả requests đều tự động có Bearer token.

3. **Error handling** - Frontend đã có error handling, backend chỉ cần return standard REST responses:
   ```json
   // Success
   { "success": true, "data": {...} }
   
   // Error
   { "error": "Error message" }
   or
   { "detail": "Error message" }
   ```

4. **Soft delete khuyến nghị** - Để giữ data integrity và có thể restore sau này.

---

## 🔗 Related Files

**Frontend:**
- `lib/features/admin/data/api/admin_api.dart` - API client đã implement
- `lib/features/admin/presentation/screens/admin_dashboard_screen.dart` - UI đã implement

**Backend:**
- `event_connect_backend/accounts/models.py` - User model
- `event_connect_backend/notifications/views.py` - Existing admin_users view (GET only)

---

## 📞 Contact

Nếu có thắc mắc về API contract hoặc cần thay đổi format response, vui lòng liên hệ Frontend team để sync.

**Created:** 2025-11-19
**Status:** 🔴 Pending Implementation
