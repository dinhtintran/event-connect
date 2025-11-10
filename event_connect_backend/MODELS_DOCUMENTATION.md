# Event Connect Backend - Model Structure Documentation

## Overview
This document describes the Django app structure and models for the Event Connect Backend system.

## App Structure

### 1. **accounts** - User Management
**Purpose**: Handles user authentication and profile management

**Models**:
- `User` (AbstractUser) - Custom user model with extended fields
  - Fields: username, email, password (inherited from AbstractUser)
  - Custom fields: role, student_id, faculty, phone, avatar, bio
  - Roles: student, club_admin, system_admin
  - Database table: `users`

**Key Features**:
- JWT authentication (configured)
- Custom user registration
- Role-based access control

---

### 2. **clubs** - Club Management
**Purpose**: Manages student clubs and their memberships

**Models**:
- `Club` - Represents student organizations
  - Fields: name, slug, description, faculty, contact info, logo, status
  - Relationships: president (User), admins (M2M with User), members (M2M through ClubMembership)
  - Status: active, inactive, suspended
  - Database table: `clubs`

- `ClubMembership` - Through model for club members
  - Fields: user, club, role, joined_at
  - Roles: member, admin, president
  - Database table: `club_memberships`
  - Unique constraint: (user, club)

---

### 3. **event_management** - Event & Registration Management
**Purpose**: Core event system including creation, registration, feedback, and approval

**Models**:

- `Event` - Main event model
  - Basic info: title, slug, description, category
  - Organizer: club, created_by
  - Location & time: location, start_at, end_at
  - Registration: registration_start, registration_end, capacity, registration_count
  - Media: poster, banner
  - Status: draft, pending, approved, rejected, ongoing, completed, cancelled
  - Categories: academic, sports, cultural, technology, volunteer, entertainment, workshop, seminar, competition, other
  - Features: is_featured, requires_approval
  - Stats: view_count, average_rating, rating_count
  - Database table: `events`
  - Properties: is_full, is_registration_open

- `EventRegistration` - Student event registrations
  - Fields: event, user, status, note, qr_code
  - Check-in: checked_in, checked_in_at
  - Status: registered, attended, cancelled, no_show
  - Database table: `event_registrations`
  - Unique constraint: (event, user)

- `Feedback` - Event feedback/reviews
  - Fields: event, user, registration, rating (1-5), comment
  - Moderation: is_approved, is_anonymous
  - Database table: `feedbacks`
  - Unique constraint: (event, user)

- `EventApproval` - Event approval workflow
  - Fields: event, reviewer, status, comment
  - Status: pending, approved, rejected
  - Timestamps: submitted_at, reviewed_at
  - Database table: `event_approvals`
  - Relationship: OneToOne with Event

- `EventImage` - Additional event images gallery
  - Fields: event, image, caption, order
  - Database table: `event_images`

---

### 4. **notifications** - Notifications & Activity Tracking
**Purpose**: User notifications and system activity logging

**Models**:

- `Notification` - User notifications
  - Fields: user, type, title, message
  - Related objects: event, club (optional)
  - Status: is_read, read_at
  - Types: event_approved, event_rejected, event_reminder, event_cancelled, event_updated, registration_confirmed, club_announcement, system
  - Database table: `notifications`
  - Index: (user, is_read)

- `ActivityLog` - System activity tracking
  - Fields: user, action, description, metadata (JSON)
  - Technical: ip_address, user_agent
  - Actions: event_created, event_updated, event_deleted, event_approved, event_rejected, user_registered, club_created, club_updated
  - Database table: `activity_logs`

---

## Database Relationships

### User Relationships
- User → Club (as president): One-to-Many
- User → Club (as admin): Many-to-Many
- User → Club (as member): Many-to-Many (through ClubMembership)
- User → Event (as creator): One-to-Many
- User → EventRegistration: One-to-Many
- User → Feedback: One-to-Many
- User → EventApproval (as reviewer): One-to-Many
- User → Notification: One-to-Many
- User → ActivityLog: One-to-Many

### Club Relationships
- Club → Event: One-to-Many
- Club → Notification: One-to-Many

### Event Relationships
- Event → EventRegistration: One-to-Many
- Event → Feedback: One-to-Many
- Event → EventApproval: One-to-One
- Event → EventImage: One-to-Many
- Event → Notification: One-to-Many

### Other Relationships
- EventRegistration → Feedback: One-to-One

---

## Key Features Implemented

### 1. Authentication & Authorization
- Custom User model based on AbstractUser
- JWT token authentication (via django-rest-framework-simplejwt)
- Role-based permissions (student, club_admin, system_admin)

### 2. Club Management
- Club creation and management
- Hierarchical roles within clubs (member, admin, president)
- Club status management

### 3. Event Lifecycle
- Draft → Pending → Approved/Rejected → Ongoing → Completed
- Optional approval workflow
- Event cancellation support

### 4. Registration System
- Capacity management
- Registration windows
- QR code support for check-in
- Attendance tracking

### 5. Feedback System
- 1-5 star ratings
- Comment support
- Moderation capabilities
- Anonymous feedback option

### 6. Notifications
- Multiple notification types
- Read/unread status tracking
- Related to events and clubs

### 7. Activity Logging
- Complete audit trail
- IP address and user agent tracking
- JSON metadata for flexibility

---

## Database Indexes

Optimized indexes for common queries:
- `events`: (status, start_at), (category, status), (is_featured, status)
- `notifications`: (user, is_read)

---

## Media Files Configuration

Media files are configured to be stored in:
- User avatars: `media/avatars/`
- Club logos: `media/club_logos/`
- Event posters: `media/event_posters/`
- Event banners: `media/event_banners/`
- Event images: `media/event_images/`

---

## Settings Configuration

Key settings added:
```python
AUTH_USER_MODEL = 'accounts.User'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'
```

---

## Installed Apps

```python
INSTALLED_APPS = [
    # Django apps
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Local apps
    'accounts',          # User management
    'clubs',             # Club management
    'event_management',  # Event & registration system
    'notifications',     # Notifications & activity logs
    
    # Third-party
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt.token_blacklist',
]
```

---

## Migrations Created

All migrations have been created for:
- ✅ accounts (0002_user_delete_profile.py)
- ✅ clubs (0001_initial.py)
- ✅ event_management (0001_initial.py)
- ✅ notifications (0001_initial.py)

**Next Steps:**
1. Configure your database credentials in settings.py
2. Run migrations: `python manage.py migrate`
3. Create a superuser: `python manage.py createsuperuser`
4. Test the admin interface
5. Implement API views and serializers for remaining apps

---

## Admin Interface

All models are registered in Django admin with:
- List displays
- Filters
- Search fields
- Readonly fields
- Custom fieldsets
- Inline editing where appropriate

---

## Notes

- The User model extends AbstractUser, so it includes all standard Django user fields
- All timestamp fields use `auto_now_add` and `auto_now` for automatic tracking
- Soft delete is not implemented - consider adding if needed
- All models have proper `__str__` methods for better admin representation
- Unique constraints are in place to prevent duplicate registrations and feedback

---

Generated: November 10, 2025
