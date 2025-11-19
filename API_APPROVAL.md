# 📋 API PHÊ DUYỆT SỰ KIỆN (EVENT APPROVAL)

## 🔑 Xác thực
- **Required**: System Admin only
- **Header**: `Authorization: Bearer <access_token>`
- **Permission**: User phải có `role = 'system_admin'` hoặc `is_superuser = True`

---

## 1️⃣ Lấy danh sách tất cả phê duyệt

### **GET** `/api/approvals/`

**Query Parameters:**
- `page`: Số trang (mặc định: 1)
- `page_size`: Số item mỗi trang (mặc định: 10, tối đa: 100)

**Response 200:**
```json
{
  "count": 10,
  "next": "http://127.0.0.1:8000/api/approvals/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "event": {
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
        "capacity": 100,
        "status": "pending"
      },
      "status": "pending",
      "submitted_at": "2025-11-15T10:00:00Z",
      "reviewed_at": null,
      "reviewer": null,
      "comment": ""
    }
  ]
}
```

**Response 403 (Permission denied):**
```json
{
  "detail": "You do not have permission to perform this action."
}
```

---

## 2️⃣ Lấy danh sách phê duyệt đang chờ

### **GET** `/api/approvals/pending/`

**Description:** Lấy danh sách các yêu cầu phê duyệt đang chờ xử lý (status = 'pending')

**Query Parameters:**
- `page`: Số trang (mặc định: 1)
- `page_size`: Số item mỗi trang (mặc định: 10, tối đa: 100)

**Response 200:**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 6,
      "event": {
        "id": 7,
        "title": "Test Event for Approval",
        "description": "Test",
        "club": {
          "id": 1,
          "name": "CLB Công nghệ",
          "slug": "clb-cong-nghe"
        },
        "start_at": "2025-11-27T00:00:00Z",
        "end_at": "2025-11-27T02:00:00Z",
        "location": "Test Location",
        "capacity": 50,
        "status": "pending"
      },
      "status": "pending",
      "submitted_at": "2025-11-17T16:28:10Z",
      "reviewed_at": null,
      "reviewer": null,
      "comment": ""
    }
  ]
}
```

---

## 3️⃣ PHÊ DUYỆT SỰ KIỆN (APPROVE) ✅

### **POST** `/api/approvals/{id}/approve/`

**Description:** Phê duyệt một sự kiện đang chờ. Chỉ System Admin mới có quyền.

**Path Parameters:**
- `id` (integer, required): ID của EventApproval cần phê duyệt

**Request Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "comment": "Sự kiện đạt yêu cầu, phê duyệt"
}
```

**Body Schema:**
- `comment` (string, optional): Nhận xét của admin khi phê duyệt

**Response 200 (Success):**
```json
{
  "message": "Event approved successfully",
  "event_id": 7,
  "approved_at": "2025-11-17T16:30:00Z"
}
```

**Response 400 (Already reviewed):**
```json
{
  "error": "Event has already been reviewed"
}
```

**Response 403 (Permission denied):**
```json
{
  "detail": "You do not have permission to perform this action."
}
```

**Response 404 (Not found):**
```json
{
  "detail": "Not found."
}
```

### 📝 Hành động sau khi phê duyệt:
1. ✅ Cập nhật `EventApproval.status = 'approved'`
2. ✅ Cập nhật `Event.status = 'approved'`
3. ✅ Lưu thời gian phê duyệt (`approved_at`)
4. ✅ Lưu người phê duyệt (`reviewer`)
5. ✅ Gửi thông báo cho người tạo sự kiện (type: `event_approved`)

---

## 4️⃣ TỪ CHỐI SỰ KIỆN (REJECT) ❌

### **POST** `/api/approvals/{id}/reject/`

**Description:** Từ chối một sự kiện đang chờ phê duyệt. Chỉ System Admin mới có quyền.

**Path Parameters:**
- `id` (integer, required): ID của EventApproval cần từ chối

**Request Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "comment": "Sự kiện không đạt yêu cầu về an toàn"
}
```

**Body Schema:**
- `comment` (string, optional): Lý do từ chối (nên điền để người tạo biết lý do)

**Response 200 (Success):**
```json
{
  "message": "Event rejected",
  "event_id": 7,
  "rejected_at": "2025-11-17T16:35:00Z"
}
```

**Response 400 (Already reviewed):**
```json
{
  "error": "Event has already been reviewed"
}
```

**Response 403 (Permission denied):**
```json
{
  "detail": "You do not have permission to perform this action."
}
```

**Response 404 (Not found):**
```json
{
  "detail": "Not found."
}
```

### 📝 Hành động sau khi từ chối:
1. ✅ Cập nhật `EventApproval.status = 'rejected'`
2. ✅ Cập nhật `Event.status = 'rejected'`
3. ✅ Lưu thời gian từ chối (`reviewed_at`)
4. ✅ Lưu người từ chối (`reviewer`)
5. ✅ Gửi thông báo cho người tạo sự kiện (type: `event_rejected`) kèm lý do

---

## 5️⃣ Chi tiết một phê duyệt

### **GET** `/api/approvals/{id}/`

**Description:** Lấy thông tin chi tiết của một yêu cầu phê duyệt

**Path Parameters:**
- `id` (integer, required): ID của EventApproval

**Response 200:**
```json
{
  "id": 6,
  "event": {
    "id": 7,
    "title": "Test Event for Approval",
    "description": "Test",
    "club": {
      "id": 1,
      "name": "CLB Công nghệ",
      "slug": "clb-cong-nghe"
    },
    "start_at": "2025-11-27T00:00:00Z",
    "end_at": "2025-11-27T02:00:00Z",
    "location": "Test Location",
    "capacity": 50,
    "status": "pending"
  },
  "status": "pending",
  "submitted_at": "2025-11-17T16:28:10Z",
  "reviewed_at": null,
  "reviewer": null,
  "comment": ""
}
```

**Response 404 (Not found):**
```json
{
  "detail": "Not found."
}
```

---

## 🎯 Use Case Frontend

### 1. Màn hình danh sách phê duyệt

```typescript
// Component: ApprovalListScreen

const fetchPendingApprovals = async () => {
  try {
    const response = await fetch('http://127.0.0.1:8000/api/approvals/pending/', {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });
    
    const data = await response.json();
    
    // Hiển thị:
    // - Tên sự kiện (event.title)
    // - CLB tổ chức (event.club.name)
    // - Thời gian bắt đầu (event.start_at)
    // - Địa điểm (event.location)
    // - 2 nút: "Phê duyệt" và "Từ chối"
    
    setApprovals(data.results);
  } catch (error) {
    console.error('Error fetching approvals:', error);
  }
};
```

### 2. Xử lý khi admin click "Phê duyệt"

```typescript
const handleApprove = async (approvalId: number) => {
  try {
    // Hiển thị dialog nhập comment (optional)
    const comment = await showCommentDialog('Nhận xét khi phê duyệt');
    
    const response = await fetch(`http://127.0.0.1:8000/api/approvals/${approvalId}/approve/`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ comment }),
    });
    
    if (response.ok) {
      const data = await response.json();
      
      // Hiển thị toast success
      showToast('success', data.message);
      
      // Refresh danh sách
      await fetchPendingApprovals();
    } else if (response.status === 400) {
      const error = await response.json();
      showToast('error', error.error);
    } else if (response.status === 403) {
      showToast('error', 'Bạn không có quyền phê duyệt');
    } else if (response.status === 404) {
      showToast('error', 'Không tìm thấy yêu cầu phê duyệt');
    }
  } catch (error) {
    console.error('Error approving event:', error);
    showToast('error', 'Có lỗi xảy ra');
  }
};
```

### 3. Xử lý khi admin click "Từ chối"

```typescript
const handleReject = async (approvalId: number) => {
  try {
    // Hiển thị dialog nhập lý do từ chối (recommended)
    const comment = await showCommentDialog('Lý do từ chối', { required: true });
    
    if (!comment) {
      showToast('warning', 'Vui lòng nhập lý do từ chối');
      return;
    }
    
    const response = await fetch(`http://127.0.0.1:8000/api/approvals/${approvalId}/reject/`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ comment }),
    });
    
    if (response.ok) {
      const data = await response.json();
      
      // Hiển thị toast
      showToast('info', data.message);
      
      // Refresh danh sách
      await fetchPendingApprovals();
    } else if (response.status === 400) {
      const error = await response.json();
      showToast('error', error.error);
    }
  } catch (error) {
    console.error('Error rejecting event:', error);
    showToast('error', 'Có lỗi xảy ra');
  }
};
```

### 4. Flutter Example

```dart
// Service: ApprovalService

class ApprovalService {
  final String baseUrl = 'http://127.0.0.1:8000/api';
  
  Future<List<EventApproval>> getPendingApprovals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/approvals/pending/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => EventApproval.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load approvals');
    }
  }
  
  Future<void> approveEvent(int approvalId, {String? comment}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/approvals/$approvalId/approve/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'comment': comment ?? ''}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Success: ${data['message']}');
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    } else {
      throw Exception('Failed to approve event');
    }
  }
  
  Future<void> rejectEvent(int approvalId, {required String comment}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/approvals/$approvalId/reject/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'comment': comment}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Success: ${data['message']}');
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      throw Exception(error['error']);
    } else {
      throw Exception('Failed to reject event');
    }
  }
}

// Widget: ApprovalListScreen
class ApprovalListScreen extends StatefulWidget {
  @override
  _ApprovalListScreenState createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> {
  final ApprovalService _service = ApprovalService();
  List<EventApproval> _approvals = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }
  
  Future<void> _loadApprovals() async {
    try {
      final approvals = await _service.getPendingApprovals();
      setState(() {
        _approvals = approvals;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  Future<void> _handleApprove(EventApproval approval) async {
    // Show dialog for comment (optional)
    final comment = await _showCommentDialog('Nhận xét');
    
    try {
      await _service.approveEvent(approval.id, comment: comment);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã phê duyệt sự kiện thành công')),
      );
      
      _loadApprovals(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  Future<void> _handleReject(EventApproval approval) async {
    // Show dialog for comment (required)
    final comment = await _showCommentDialog('Lý do từ chối', required: true);
    
    if (comment == null || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
      );
      return;
    }
    
    try {
      await _service.rejectEvent(approval.id, comment: comment);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã từ chối sự kiện')),
      );
      
      _loadApprovals(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  Future<String?> _showCommentDialog(String title, {bool required = false}) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: required ? 'Bắt buộc nhập' : 'Tùy chọn',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _approvals.length,
      itemBuilder: (context, index) {
        final approval = _approvals[index];
        final event = approval.event;
        
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLB: ${event.club.name}'),
                Text('Địa điểm: ${event.location}'),
                Text('Thời gian: ${event.startAt}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () => _handleApprove(approval),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => _handleReject(approval),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## 🔒 Quyền truy cập

| Endpoint | Method | Permission Required | Mô tả |
|----------|--------|---------------------|-------|
| `/api/approvals/` | GET | System Admin | Xem tất cả phê duyệt |
| `/api/approvals/pending/` | GET | System Admin | Xem phê duyệt đang chờ |
| `/api/approvals/{id}/` | GET | System Admin | Xem chi tiết 1 phê duyệt |
| `/api/approvals/{id}/approve/` | POST | System Admin | Phê duyệt sự kiện |
| `/api/approvals/{id}/reject/` | POST | System Admin | Từ chối sự kiện |

**Lưu ý:** Tất cả endpoints đều yêu cầu user có:
- `role = 'system_admin'` HOẶC
- `is_superuser = True`

---

## ✅ Testing với cURL

### 1. Login để lấy token (System Admin)
```bash
curl -X POST http://127.0.0.1:8000/api/accounts/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }'

# Response:
# {
#   "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#   "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
# }
```

### 2. Lấy danh sách pending
```bash
curl -X GET http://127.0.0.1:8000/api/approvals/pending/ \
  -H "Authorization: Bearer <access_token>"
```

### 3. Phê duyệt sự kiện
```bash
curl -X POST http://127.0.0.1:8000/api/approvals/6/approve/ \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "comment": "Sự kiện đã được kiểm tra và phê duyệt"
  }'
```

### 4. Từ chối sự kiện
```bash
curl -X POST http://127.0.0.1:8000/api/approvals/7/reject/ \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "comment": "Nội dung sự kiện không phù hợp với quy định"
  }'
```

### 5. Lấy chi tiết 1 approval
```bash
curl -X GET http://127.0.0.1:8000/api/approvals/6/ \
  -H "Authorization: Bearer <access_token>"
```

---

## 🔄 Workflow phê duyệt sự kiện

```
1. Club Admin tạo sự kiện
   └─> Event.status = 'draft'

2. Club Admin submit sự kiện để phê duyệt
   └─> Event.status = 'pending'
   └─> EventApproval được tạo với status = 'pending'

3. System Admin xem danh sách pending
   └─> GET /api/approvals/pending/

4a. System Admin PHÂN DUYỆT:
    └─> POST /api/approvals/{id}/approve/
    └─> EventApproval.status = 'approved'
    └─> Event.status = 'approved'
    └─> Gửi notification cho Club Admin (type: event_approved)

4b. System Admin TỪ CHỐI:
    └─> POST /api/approvals/{id}/reject/
    └─> EventApproval.status = 'rejected'
    └─> Event.status = 'rejected'
    └─> Gửi notification cho Club Admin (type: event_rejected)

5. Club Admin nhận notification và biết kết quả
```

---

## 📊 Status Flow

### EventApproval Status:
- `pending`: Đang chờ phê duyệt
- `approved`: Đã phê duyệt
- `rejected`: Đã từ chối

### Event Status liên quan:
- `draft`: Nháp (chưa submit)
- `pending`: Chờ phê duyệt (đã submit, EventApproval.status = pending)
- `approved`: Đã được phê duyệt (EventApproval.status = approved)
- `rejected`: Bị từ chối (EventApproval.status = rejected)
- `ongoing`: Đang diễn ra
- `completed`: Đã hoàn thành
- `cancelled`: Đã hủy

---

## 🎨 UI/UX Recommendations

### Màn hình danh sách phê duyệt:
1. **Filter tabs:**
   - "Đang chờ" (pending) - mặc định
   - "Tất cả" (all)
   
2. **Card cho mỗi approval:**
   - Thumbnail sự kiện (poster)
   - Tên sự kiện (title)
   - CLB tổ chức (club.name)
   - Thời gian & địa điểm
   - Badge hiển thị status (pending/approved/rejected)
   - 2 action buttons: "Phê duyệt" (màu xanh) và "Từ chối" (màu đỏ)

3. **Khi click "Phê duyệt":**
   - Hiển thị confirmation dialog
   - Có text field để nhập comment (optional)
   - 2 buttons: "Hủy" và "Xác nhận phê duyệt"

4. **Khi click "Từ chối":**
   - Hiển thị dialog YÊU CẦU nhập lý do
   - Text field bắt buộc nhập
   - 2 buttons: "Hủy" và "Xác nhận từ chối"

5. **Sau khi approve/reject:**
   - Hiển thị toast/snackbar thông báo
   - Auto-refresh danh sách pending
   - Item vừa xử lý biến mất khỏi tab "Đang chờ"

---

## 🐛 Error Handling

### Common Errors:

1. **401 Unauthorized:**
   - Token hết hạn hoặc không hợp lệ
   - Action: Redirect to login

2. **403 Forbidden:**
   - User không phải System Admin
   - Action: Hiển thị thông báo "Bạn không có quyền thực hiện"

3. **404 Not Found:**
   - EventApproval không tồn tại
   - Action: Refresh danh sách và thông báo lỗi

4. **400 Bad Request:**
   - EventApproval đã được review rồi
   - Action: Hiển thị message từ server và refresh danh sách

---

## 📱 Base URL

**Development:** `http://127.0.0.1:8000/api`  
**Production:** `https://your-domain.com/api`

---

## 🚀 Quick Start cho Frontend Developer

1. **Login với System Admin account:**
   ```
   POST /api/accounts/login/
   Body: { email, password }
   → Lưu access_token
   ```

2. **Lấy danh sách pending:**
   ```
   GET /api/approvals/pending/
   Header: Authorization: Bearer <token>
   ```

3. **Phê duyệt hoặc từ chối:**
   ```
   POST /api/approvals/{id}/approve/
   POST /api/approvals/{id}/reject/
   Body: { comment: "..." }
   ```

4. **Handle response và refresh UI**

---

## 📞 Support

Nếu có lỗi hoặc cần thêm endpoint, liên hệ Backend Team! 🎉
