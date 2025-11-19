# Tính năng Xóa Sự kiện

## Tổng quan
Tính năng cho phép quản trị viên câu lạc bộ xóa các sự kiện **chưa được phê duyệt** mà câu lạc bộ đã tạo ra.

## Quy tắc nghiệp vụ
- ✅ Chỉ cho phép xóa sự kiện có trạng thái **KHÔNG PHẢI** `approved` (đã phê duyệt)
- ✅ Các trạng thái có thể xóa: `draft`, `pending`, `rejected`, `completed`
- ❌ Không thể xóa sự kiện đã được phê duyệt (`approved`)
- ✅ Chỉ quản trị viên câu lạc bộ hoặc người tạo sự kiện mới có quyền xóa

## Thay đổi Backend

### File: `event_connect_backend/event_management/views.py`

Thêm phương thức `destroy` vào `EventViewSet`:

```python
def destroy(self, request, *args, **kwargs):
    """Delete an event - only allowed for non-approved events"""
    instance = self.get_object()
    
    # Check if user is the club admin or event creator
    if not (request.user.profile.is_club_admin and 
            request.user.profile.club_id == instance.club.id):
        if instance.created_by != request.user:
            return Response(
                {'error': 'You do not have permission to delete this event'},
                status=status.HTTP_403_FORBIDDEN
            )
    
    # Check if event is approved - cannot delete approved events
    if instance.status == 'approved':
        return Response(
            {'error': 'Cannot delete approved events'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Delete the event
    instance.delete()
    
    return Response(
        {'message': 'Event deleted successfully'},
        status=status.HTTP_204_NO_CONTENT
    )
```

**Endpoint:** `DELETE /api/events/{id}/`

## Thay đổi Frontend

### 1. EventApi - `lib/features/event_management/data/api/event_api.dart`

Thêm method để gọi DELETE endpoint:

```dart
/// DELETE /api/events/{id}/ - Xóa sự kiện (Club Admin)
Future<Map<String, dynamic>> deleteEvent(String eventId) async {
  _dbg('DELETE /api/events/$eventId/');
  try {
    final res = await dio.delete('/api/events/$eventId/');
    _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
    return {'status': res.statusCode, 'body': res.data ?? {'message': 'Event deleted successfully'}};
  } on DioException catch (e) {
    _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
    return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
  } catch (e) {
    _dbg('Exception: $e');
    return {'status': 0, 'body': {'detail': e.toString()}};
  }
}
```

### 2. ClubAdminApi - `lib/features/event_creation/data/api/club_admin_api.dart`

```dart
/// Xóa sự kiện (chỉ cho phép xóa sự kiện chưa được phê duyệt)
Future<Map<String, dynamic>> deleteEvent(String eventId) async {
  _dbg('deleteEvent: eventId=$eventId');
  return await eventApi.deleteEvent(eventId);
}
```

### 3. ClubAdminRepository - `lib/features/event_creation/data/repositories/club_admin_repository.dart`

```dart
/// Xóa sự kiện (chỉ cho phép xóa sự kiện chưa được phê duyệt)
Future<void> deleteEvent(String eventId) async {
  final result = await api.deleteEvent(eventId);
  if (result['status'] != 204 && result['status'] != 200) {
    throw Exception(result['body']['detail'] ?? result['body']['error'] ?? 'Failed to delete event');
  }
}
```

### 4. ClubEventCard Widget - `lib/features/event_creation/presentation/widgets/club_event_card.dart`

Thêm các thuộc tính mới:

```dart
final VoidCallback? onDelete;
final bool canDelete; // Cho phép xóa hay không (dựa vào trạng thái)

const ClubEventCard({
  // ... existing parameters
  this.onDelete,
  this.canDelete = false,
});
```

Thêm nút xóa vào danh sách action buttons:

```dart
if (canDelete && onDelete != null)
  OutlinedButton.icon(
    onPressed: onDelete,
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.red,
      side: const BorderSide(color: Colors.red),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    icon: const Icon(Icons.delete_outline, size: 18),
    label: const Text('Xóa'),
  ),
```

### 5. ClubEventsPage - `lib/features/event_creation/presentation/screens/club_events_page.dart`

#### Thêm methods xử lý xóa:

```dart
void _showDeleteConfirmation(Event event) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text('Bạn có chắc chắn muốn xóa sự kiện "${event.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _deleteEvent(event);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Xóa', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Future<void> _deleteEvent(Event event) async {
  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
  
  try {
    await _repository.deleteEvent(event.id.toString());
    
    // Close loading dialog
    if (mounted) Navigator.pop(context);
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa sự kiện thành công'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    // Reload events
    _loadEvents();
  } catch (e) {
    // Close loading dialog
    if (mounted) Navigator.pop(context);
    
    // Show error message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa sự kiện: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

#### Cập nhật render ClubEventCard:

```dart
..._events.map((event) {
  // Chỉ cho phép xóa sự kiện chưa được phê duyệt
  final canDelete = event.status != 'approved';
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: ClubEventCard(
      status: _getStatusText(event),
      statusColor: _getStatusColor(event),
      title: event.title,
      date: _formatDate(event.startAt),
      location: event.location,
      organizer: event.clubName,
      image: event.posterUrl,
      canDelete: canDelete,
      onEdit: () => _navigateToEditEvent(event),
      onViewParticipants: () => _navigateToParticipants(event),
      onDelete: canDelete ? () => _showDeleteConfirmation(event) : null,
      onTap: () => _navigateToEventDetail(event),
    ),
  );
}).toList(),
```

## Luồng hoạt động

1. **Hiển thị nút xóa**: Nút "Xóa" chỉ hiển thị cho các sự kiện có `status != 'approved'`

2. **Người dùng click nút Xóa**: 
   - Hiển thị dialog xác nhận với tên sự kiện

3. **Người dùng xác nhận xóa**:
   - Gửi request `DELETE /api/events/{id}/` đến backend
   - Hiển thị loading indicator

4. **Backend xử lý**:
   - Kiểm tra quyền (phải là club admin hoặc người tạo)
   - Kiểm tra trạng thái (không được là `approved`)
   - Xóa sự kiện khỏi database
   - Trả về status 204 (No Content)

5. **Frontend xử lý response**:
   - **Thành công**: Hiển thị SnackBar xanh, reload danh sách sự kiện
   - **Lỗi**: Hiển thị SnackBar đỏ với thông báo lỗi

## Xử lý lỗi

### Backend
- `403 Forbidden`: Người dùng không có quyền xóa sự kiện
- `400 Bad Request`: Sự kiện đã được phê duyệt, không thể xóa
- `404 Not Found`: Không tìm thấy sự kiện

### Frontend
- Hiển thị thông báo lỗi trong SnackBar
- Không reload danh sách nếu xóa thất bại
- Dialog xác nhận có thể hủy bỏ

## Bảo mật

- ✅ Backend kiểm tra quyền trước khi xóa
- ✅ Frontend ẩn nút xóa cho sự kiện đã phê duyệt
- ✅ Dialog xác nhận trước khi xóa (tránh xóa nhầm)
- ✅ Không thể xóa sự kiện đã được phê duyệt (bảo vệ dữ liệu quan trọng)

## Testing

### Test cases cần kiểm tra:

1. ✅ Xóa sự kiện có status = `draft` → Thành công
2. ✅ Xóa sự kiện có status = `pending` → Thành công
3. ✅ Xóa sự kiện có status = `rejected` → Thành công
4. ❌ Xóa sự kiện có status = `approved` → Lỗi 400
5. ❌ Người dùng không phải club admin xóa sự kiện → Lỗi 403
6. ✅ Hủy dialog xác nhận → Không xóa sự kiện
7. ✅ Reload danh sách sau khi xóa thành công

## Ghi chú

- Khi xóa sự kiện, tất cả dữ liệu liên quan (registrations, feedbacks, images) cũng sẽ bị xóa theo (CASCADE delete trong database)
- Không có chức năng "soft delete" - sự kiện bị xóa hoàn toàn khỏi database
- Cân nhắc thêm chức năng "archive" thay vì xóa hoàn toàn trong tương lai
