# Event Connect Backend - API Implementation Guide

## ✅ Completed Implementation

All 25 API endpoints from the specification have been implemented successfully!

## 📍 API Endpoints Overview

### Base URL
```
http://127.0.0.1:8000/api
```

---

## 🎯 EVENT MANAGEMENT APIs

### 1. GET /events/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.list()`  
**Permissions**: Public (read-only)  
**Query Parameters**:
- `page`: Page number
- `page_size`: Items per page (max 100)
- `status`: Filter by status
- `category`: Filter by category
- `is_featured`: Boolean filter
- `club_id`: Filter by club
- `ordering`: Sort field (e.g., `-start_at`)

### 2. GET /events/{id}/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.retrieve()`  
**Permissions**: Public (read-only)  
**Features**: Auto-increment view count

### 3. GET /events/featured/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.featured()`  
**Permissions**: Public  
**Query Parameters**: `limit` (max 20)

### 4. GET /events/search/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.search()`  
**Permissions**: Public  
**Query Parameters**: `q` (required), `page`

### 5. POST /events/{id}/register/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.register()`  
**Permissions**: Authenticated users  
**Features**:
- Validates capacity
- Checks registration window
- Prevents duplicate registration
- Generates QR code
- Sends notification

### 6. POST /events/{id}/unregister/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.unregister()`  
**Permissions**: Authenticated users

### 7. GET /registrations/my-events/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventRegistrationViewSet.my_events()`  
**Permissions**: Authenticated users  
**Query Parameters**: `status`, `upcoming`

### 8. POST /events/{id}/feedback/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.feedback()`  
**Permissions**: Authenticated users (must have attended)  
**Features**:
- Validates attendance
- Prevents duplicate feedback
- Updates event rating statistics

### 9. GET /events/{id}/feedbacks/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.feedbacks()`  
**Permissions**: Public  
**Features**: Returns rating distribution

---

## 🏢 CLUB MANAGEMENT APIs

### 10. GET /clubs/
**Status**: ✅ Implemented  
**File**: `clubs/views.py` - `ClubViewSet.list()`  
**Permissions**: Public (read-only)  
**Query Parameters**: `status`, `faculty`, `page`

### 11. GET /clubs/{id}/
**Status**: ✅ Implemented  
**File**: `clubs/views.py` - `ClubViewSet.retrieve()`  
**Permissions**: Public  
**Features**: Includes upcoming events

### 12. POST /clubs/
**Status**: ✅ Implemented  
**File**: `clubs/views.py` - `ClubViewSet.create()`  
**Permissions**: System Admin only

---

## 📈 CLUB STATISTICS APIs

### GET /clubs/{id}/statistics/
**Status**: ✅ Implemented  
**File**: `clubs/views.py` - `ClubViewSet.statistics()`  
**Permissions**: Club president/admin, club creator, or system admin  
**Caching**: `Cache-Control: private, max-age=300`  
**Query Parameters**:
- `range_days` (30–180, default 90)
- `limit_feedback` (1–10, default 3)
- `limit_highlights` (1–12, default 6)

**Response**: Consolidated payload with overview metrics, change deltas, six-month attendance series, academic distribution, curated feedback samples, highlights, and `is_empty` flag. When a club has no events, the endpoint still returns zeroed metrics so the frontend can show an empty state.

**Error Codes**:
- `club_statistics_forbidden` for unauthorized users
- `invalid_statistics_param` for bad query parameters
- `statistics_generation_failed` for transient back-end issues

### GET /clubs/{id}/statistics/raw-events/
**Status**: ✅ Implemented  
**File**: `clubs/views.py` - `ClubViewSet.statistics_raw_events()`  
**Permissions**: Same as main statistics endpoint  
**Query Parameters**:
- `range_days` (30–180, default 90)
- `limit` (1–200, default 50)

**Response**: Lightweight list of events (id, title, start/end timestamps, status, category, rating stats, attended/registered counts, poster URL) used for debugging and advanced charting.

**Security Notes**:
- Permission helper enforces membership checks before any caching.
- All payloads add machine-readable `error_code` values for predictable frontend handling.

---

## 📝 EVENT CREATION APIs

### 13. POST /clubs/{club_id}/events/
**Status**: ✅ Implemented  
**File**: `clubs/views.py` - `ClubViewSet.events()`  
**Permissions**: Club Admin only  
**Features**:
- Auto-generates slug
- Creates approval record if needed
- Logs activity

### 14. PUT /events/{id}/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.update()`  
**Permissions**: Event creator or club admin

### 15. GET /events/{id}/participants/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.participants()`  
**Permissions**: Event creator or club admin  
**Query Parameters**: `status`

### 16. POST /events/{id}/upload-poster/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventViewSet.upload_poster()`  
**Permissions**: Event creator or club admin

---

## ✅ EVENT APPROVAL APIs

### 17. GET /approvals/pending/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventApprovalViewSet.pending()`  
**Permissions**: System Admin only

### 18. POST /approvals/{event_id}/approve/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventApprovalViewSet.approve()`  
**Permissions**: System Admin only  
**Features**: Sends notification to event creator

### 19. POST /approvals/{event_id}/reject/
**Status**: ✅ Implemented  
**File**: `event_management/views.py` - `EventApprovalViewSet.reject()`  
**Permissions**: System Admin only  
**Features**: Sends notification with reason

---

## 📊 ADMIN DASHBOARD APIs

### 20. GET /admin/stats/
**Status**: ✅ Implemented  
**File**: `notifications/views.py` - `admin_stats()`  
**Permissions**: System Admin only  
**Query Parameters**: `period` (week/month)  
**Returns**:
- Overview statistics
- Events by status
- Recent activity
- Top events
- Top clubs

### 21. GET /admin/activities/
**Status**: ✅ Implemented  
**File**: `notifications/views.py` - `admin_activities()`  
**Permissions**: System Admin only  
**Query Parameters**: `page`, `limit`

### 22. GET /admin/users/
**Status**: ✅ Implemented  
**File**: `notifications/views.py` - `admin_users()`  
**Permissions**: System Admin only  
**Query Parameters**: `role`, `search`, `page`, `page_size`

---

## 📱 ADMIN REPORTS (Mobile Dashboard)

All reporting endpoints live under `/api/admin/reports/` and are protected by role-based scope:

| Endpoint | Description | Notes |
|----------|-------------|-------|
| `GET /overview/` | High-level KPIs (events, users, revenue proxy, complaints) | Accepts `range`, `from`, `to`, `facultyId`, `eventType` |
| `GET /users/metrics/` | Signup + engagement stats with sparkline + top faculties | Includes DAU/WAU, conversion, inactive users |
| `GET /users/list/` | Paginated drill-down of users | Supports `status`, `search`, `page`, `pageSize` |
| `GET /clubs/metrics/` | Club activity, growth, revenue contribution | Returns comparison dataset for charts |
| `GET /clubs/list/` | Tabular club health view | Flags `needsSupport`, `complianceWarning`; sortable via `sort` |
| `GET /events/metrics/` | Approval SLA, cancellations, fill rate, satisfaction | Uses real registration + feedback data |
| `GET /events/timeline/` | Live/upcoming feed with risk score + headcount | Filterable via shared range filters |
| `GET /alerts/` | Consolidated risk cards (pending approvals, complaints, cancellations) | Query by `severity` or `type` |
| `POST /export/` | Kick off export job with `sections[]` payload | Returns job descriptor (202) |
| `GET /export/{jobId}/` | Poll export job status/result | Includes serialized payload for now |
| `GET /config` / `PUT /config` | Persist dashboard layout + default filters per admin | Stored in `ReportDashboardConfig` |
| `GET /audit/` | Compliance log sourced from `ActivityLog` | Filters by `actorId`, `actionType`, range |

**Shared contract**:
- Every response wraps data with `meta` containing `range`, actual time window, `lastUpdated`, `degraded`, `cacheVersion`, and `scope` descriptor (global vs faculty-scoped).
- Filters: `range`, `from`, `to`, `facultyId`, `departmentId` (ignored but reported), `clubIds`, `eventType`, `status`, `page`, `pageSize` depending on endpoint.
- Scope enforcement: non-system admins are auto-restricted to their faculty; unsupported filters mark `degraded=true` with `notes.ignoredFilters`.
- Export jobs persist in `report_export_jobs`, configs in `report_dashboard_configs`, both created via the new `admin_reports` app.

See `admin_reports/services.py` for the aggregation logic and `admin_reports/tests/test_admin_reports_api.py` for live contract tests.

---

## 🔔 NOTIFICATION APIs

### 23. GET /notifications/
**Status**: ✅ Implemented  
**File**: `notifications/views.py` - `NotificationViewSet.list()`  
**Permissions**: Authenticated users  
**Query Parameters**: `is_read`  
**Features**: Returns unread count

### 24. POST /notifications/{id}/read/
**Status**: ✅ Implemented  
**File**: `notifications/views.py` - `NotificationViewSet.read()`  
**Permissions**: Authenticated users

### 25. GET /notifications/unread-count/
**Status**: ✅ Implemented  
**File**: `notifications/views.py` - `NotificationViewSet.unread_count()`  
**Permissions**: Authenticated users

### Bonus: POST /notifications/mark-all-read/
**Status**: ✅ Implemented (Extra feature)  
**File**: `notifications/views.py` - `NotificationViewSet.mark_all_read()`  
**Permissions**: Authenticated users

---

## 🔐 Permission System

### Permission Classes
All permission classes are implemented in `event_management/permissions.py`:

1. **IsClubAdminOrReadOnly** - For club-related actions
2. **IsEventCreatorOrClubAdmin** - For event management
3. **IsSystemAdmin** - For admin-only endpoints
4. **IsClubAdmin** - For club administrators

### Permission Matrix

| Endpoint | Student | Club Admin | System Admin |
|----------|---------|------------|--------------|
| GET /events/ | ✅ | ✅ | ✅ |
| POST /events/{id}/register/ | ✅ | ✅ | ❌ |
| POST /clubs/{id}/events/ | ❌ | ✅ (own club) | ✅ |
| PUT /events/{id}/ | ❌ | ✅ (own event) | ✅ |
| POST /approvals/{id}/approve/ | ❌ | ❌ | ✅ |
| GET /admin/stats/ | ❌ | ❌ | ✅ |
| POST /clubs/ | ❌ | ❌ | ✅ |

---

## 📁 File Structure

```
event_connect_backend/
├── event_management/
│   ├── models.py          # Event, EventRegistration, Feedback, etc.
│   ├── serializers.py     # ✅ All event serializers
│   ├── views.py           # ✅ EventViewSet, EventRegistrationViewSet, EventApprovalViewSet
│   ├── permissions.py     # ✅ Custom permissions
│   ├── urls.py            # ✅ Event API routes
│   └── admin.py           # Admin interface
│
├── clubs/
│   ├── models.py          # Club, ClubMembership
│   ├── serializers.py     # ✅ Club serializers
│   ├── views.py           # ✅ ClubViewSet
│   ├── urls.py            # ✅ Club API routes
│   └── admin.py           # Admin interface
│
├── notifications/
│   ├── models.py          # Notification, ActivityLog
│   ├── serializers.py     # ✅ Notification serializers
│   ├── views.py           # ✅ NotificationViewSet, admin views
│   ├── urls.py            # ✅ Notification API routes
│   └── admin.py           # Admin interface
│
├── accounts/
│   ├── models.py          # Custom User model
│   ├── serializers.py     # ✅ Updated User serializers
│   ├── views.py           # Authentication views
│   ├── urls.py            # Auth routes
│   └── admin.py           # User admin
│
└── event_connect_backend/
    ├── settings.py        # ✅ All apps configured
    └── urls.py            # ✅ Main URL config
```

---

## 🚀 Quick Start Guide

### 1. Apply Migrations
```bash
python manage.py migrate
```

### 2. Create Superuser
```bash
python manage.py createsuperuser
```

### 3. Run Server
```bash
python manage.py runserver
```

### 4. Test APIs

#### Get JWT Token
```bash
POST /api/accounts/login/
{
  "username": "admin",
  "password": "password"
}
```

#### List Events
```bash
GET /api/events/
Authorization: Bearer {access_token}
```

#### Create Club (System Admin)
```bash
POST /api/clubs/
Authorization: Bearer {access_token}
{
  "name": "Tech Club",
  "description": "Technology enthusiasts",
  "faculty": "Computer Science",
  "contact_email": "tech@university.edu.vn",
  "president_id": 1
}
```

#### Create Event (Club Admin)
```bash
POST /api/clubs/1/events/
Authorization: Bearer {access_token}
{
  "title": "Hackathon 2025",
  "description": "Annual coding competition",
  "category": "competition",
  "location": "Main Hall",
  "start_at": "2025-12-15T09:00:00Z",
  "end_at": "2025-12-15T17:00:00Z",
  "capacity": 100
}
```

#### Register for Event (Student)
```bash
POST /api/events/1/register/
Authorization: Bearer {access_token}
{
  "note": "Looking forward to participating!"
}
```

---

## 🎨 API Response Examples

### Success Response
```json
{
  "id": 1,
  "title": "Hackathon 2025",
  "status": "approved",
  "created_at": "2025-11-10T10:00:00Z"
}
```

### Error Responses

#### 400 Bad Request
```json
{
  "error": "Event is full",
  "capacity": 100,
  "current_registrations": 100
}
```

#### 401 Unauthorized
```json
{
  "detail": "Authentication credentials were not provided."
}
```

#### 403 Forbidden
```json
{
  "detail": "You do not have permission to perform this action."
}
```

#### 404 Not Found
```json
{
  "detail": "Not found."
}
```

---

## 📝 Additional Features Implemented

### 1. Automatic Slug Generation
Events and clubs automatically get URL-friendly slugs from their names.

### 2. Club Statistics QA Fixture
Load `fixtures/club_statistics_sample.json` to seed a demo club that covers six months of historical events:

```bash
python manage.py loaddata fixtures/club_statistics_sample.json
```
The fixture provisions a club admin (`stats-admin` / `DemoPass123!`) plus sample members, events, registrations, and feedback so the dashboard can be tested without manual data entry.

### 2. QR Code Generation
Each registration gets a unique QR code: `EVT-{event_id}-USR-{user_id}-{random}`

### 3. Activity Logging
All major actions are logged in `ActivityLog` with metadata.

### 4. Notification System
Automatic notifications for:
- Event approval/rejection
- Registration confirmation
- Event reminders

### 5. Rating System
Automatic calculation of average ratings and rating distribution.

### 6. View Counter
Event views are automatically tracked.

### 7. Pagination
All list endpoints support pagination with configurable page sizes.

---

## 🧪 Testing Recommendations

### 1. Unit Tests
Create tests for:
- Event registration validation
- Permission checks
- Rating calculations
- QR code generation

### 2. Integration Tests
Test complete workflows:
- Event creation → approval → registration → check-in → feedback
- Club creation → add members → create event

### 3. API Tests
Use tools like:
- Postman
- Thunder Client (VS Code extension)
- pytest with Django REST framework

---

## 🔧 Configuration

### Required Settings
All configurations are in `event_connect_backend/settings.py`:

```python
# Custom User Model
AUTH_USER_MODEL = 'accounts.User'

# Media Files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
}

# JWT Settings
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}
```

---

## 📚 Next Steps

1. ✅ All API endpoints implemented
2. ⏳ Add comprehensive unit tests
3. ⏳ Add API documentation (Swagger/OpenAPI)
4. ⏳ Implement real-time notifications (WebSockets)
5. ⏳ Add email notifications
6. ⏳ Implement file upload validation
7. ⏳ Add rate limiting
8. ⏳ Deploy to production

---

## 🐛 Known Limitations

1. **Search**: Basic string matching (consider adding Elasticsearch)
2. **Real-time**: No WebSocket support yet
3. **Email**: No email notifications yet
4. **File Validation**: Basic file upload without size/type validation
5. **Caching**: No caching implemented yet

---

## 📞 Support

For issues or questions:
1. Check the documentation
2. Review error messages carefully
3. Check Django logs: `python manage.py runserver` output
4. Use Django shell for debugging: `python manage.py shell`

---

**Status**: All 25 API endpoints ✅ FULLY IMPLEMENTED

**Generated**: November 10, 2025  
**Version**: 1.0.0
