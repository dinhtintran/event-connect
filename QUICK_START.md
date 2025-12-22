# Event Connect Backend - Quick Start Guide

## 📋 What Has Been Created

### ✅ Completed Tasks

1. **4 Django Apps Created/Updated:**
   - `accounts` - User authentication and management
   - `clubs` - Club and membership management
   - `event_management` - Events, registrations, feedback, approvals
   - `notifications` - Notifications and activity logging

2. **13 Models Defined:**
   - User (accounts)
   - Club, ClubMembership (clubs)
   - Event, EventRegistration, Feedback, EventApproval, EventImage (event_management)
   - Notification, ActivityLog (notifications)

3. **Admin Interface:**
   - All models registered with rich admin features
   - List displays, filters, search, and custom fieldsets

4. **Migrations:**
   - All initial migrations created and ready to apply

5. **Settings Updated:**
   - Custom User model configured
   - All apps registered
   - Media files configuration added

---

## 🚀 Next Steps to Get Started

### Step 1: Configure Database
Update your database credentials in `event_connect_backend/settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'event_connect',
        'USER': 'your_username',      # Update this
        'PASSWORD': 'your_password',  # Update this
        'HOST': 'localhost',
        'PORT': '3306',
    }
}
```

### Step 2: Apply Migrations

```bash
# Apply all migrations to create database tables
python manage.py migrate
```

### Step 3: Create Superuser

```bash
# Create an admin account
python manage.py createsuperuser
```

When prompted, enter:
- Username
- Email
- Password

### Step 4: Run Development Server

```bash
# Start the Django development server
python manage.py runserver
```

### Step 5: Access Admin Interface

Visit: http://127.0.0.1:8000/admin/

Login with your superuser credentials to:
- Create users
- Manage clubs
- Create events
- View registrations
- Manage notifications

---

## 📁 Project Structure

```
backend-event-connect/
├── accounts/              # User management
│   ├── migrations/
│   ├── __init__.py
│   ├── admin.py          # ✅ User admin
│   ├── apps.py
│   ├── models.py         # ✅ User model
│   ├── serializers.py    # ✅ Updated serializers
│   ├── signals.py        # ✅ Updated (cleaned)
│   ├── urls.py
│   └── views.py          # ✅ Updated imports
│
├── clubs/                 # Club management
│   ├── migrations/
│   ├── __init__.py
│   ├── admin.py          # ✅ Club, ClubMembership admin
│   ├── apps.py           # ✅ Created
│   └── models.py         # ✅ Club, ClubMembership models
│
├── event_management/      # Event system
│   ├── migrations/
│   ├── __init__.py
│   ├── admin.py          # ✅ All event models admin
│   ├── apps.py           # ✅ Created
│   └── models.py         # ✅ 5 event-related models
│
├── notifications/         # Notifications & logs
│   ├── migrations/
│   ├── __init__.py
│   ├── admin.py          # ✅ Notification, ActivityLog admin
│   ├── apps.py           # ✅ Created
│   └── models.py         # ✅ 2 notification models
│
├── event_connect_backend/
│   ├── __init__.py
│   ├── settings.py       # ✅ Updated (AUTH_USER_MODEL, MEDIA)
│   ├── urls.py
│   └── wsgi.py
│
├── manage.py
├── requirements.txt
├── README.md
└── MODELS_DOCUMENTATION.md  # ✅ Comprehensive documentation
```

---

## 🔧 API Development - Next Steps

### 1. Create Serializers

For each app, create serializers for API endpoints:

**Example for clubs app** (`clubs/serializers.py`):
```python
from rest_framework import serializers
from .models import Club, ClubMembership
from accounts.serializers import UserSerializer

class ClubSerializer(serializers.ModelSerializer):
    president = UserSerializer(read_only=True)
    member_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Club
        fields = '__all__'
        read_only_fields = ('slug', 'created_at', 'updated_at')
    
    def get_member_count(self, obj):
        return obj.members.count()

class ClubMembershipSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    club = ClubSerializer(read_only=True)
    
    class Meta:
        model = ClubMembership
        fields = '__all__'
```

### 2. Create ViewSets

**Example** (`clubs/views.py`):
```python
from rest_framework import viewsets, permissions
from .models import Club, ClubMembership
from .serializers import ClubSerializer, ClubMembershipSerializer

class ClubViewSet(viewsets.ModelViewSet):
    queryset = Club.objects.filter(status='active')
    serializer_class = ClubSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'slug'
    
    def get_queryset(self):
        queryset = super().get_queryset()
        faculty = self.request.query_params.get('faculty')
        if faculty:
            queryset = queryset.filter(faculty=faculty)
        return queryset
```

### 3. Configure URLs

**Create** (`clubs/urls.py`):
```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'clubs', views.ClubViewSet, basename='club')

urlpatterns = [
    path('', include(router.urls)),
]
```

**Update main URLs** (`event_connect_backend/urls.py`):
```python
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/accounts/', include('accounts.urls')),
    path('api/', include('clubs.urls')),                    # Add
    path('api/', include('event_management.urls')),        # Add
    path('api/', include('notifications.urls')),           # Add
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

---

## 🧪 Testing the Models

### In Django Shell

```bash
python manage.py shell
```

```python
from accounts.models import User
from clubs.models import Club, ClubMembership
from event_management.models import Event, EventRegistration

# Create a user
user = User.objects.create_user(
    username='john_doe',
    email='john@example.com',
    password='password123',
    role='student',
    student_id='STD001',
    faculty='Computer Science'
)

# Create a club
club = Club.objects.create(
    name='Tech Club',
    slug='tech-club',
    description='A club for tech enthusiasts',
    faculty='Computer Science',
    contact_email='tech@example.com',
    president=user
)

# Add member
membership = ClubMembership.objects.create(
    user=user,
    club=club,
    role='president'
)

# Create an event
event = Event.objects.create(
    title='Django Workshop',
    slug='django-workshop',
    description='Learn Django framework',
    category='workshop',
    club=club,
    created_by=user,
    location='Room 301',
    start_at='2025-12-01 14:00:00',
    end_at='2025-12-01 17:00:00',
    capacity=50,
    status='approved'
)

print(f"✅ Created: {user}, {club}, {event}")
```

---

## 📊 Common Queries Examples

### Get all active events
```python
Event.objects.filter(status='approved', start_at__gte=timezone.now())
```

### Get user's registered events
```python
user.event_registrations.filter(status='registered')
```

### Get club members
```python
club.members.all()
```

### Get event registrations count
```python
event.registrations.count()
```

### Get unread notifications
```python
Notification.objects.filter(user=user, is_read=False)
```

### Get club's upcoming events
```python
club.events.filter(start_at__gte=timezone.now(), status='approved')
```

---

## 🎯 Features to Implement

### Priority 1 - Core Features
- [ ] Event CRUD API endpoints
- [ ] Event registration API
- [ ] Event search and filtering
- [ ] User profile management API
- [ ] Club management API

### Priority 2 - Advanced Features
- [ ] Event approval workflow
- [ ] QR code generation for registrations
- [ ] Check-in system
- [ ] Feedback/rating system
- [ ] Notification system (real-time with WebSockets?)

### Priority 3 - Enhancement Features
- [ ] Event recommendations
- [ ] Analytics dashboard
- [ ] Export attendance reports
- [ ] Email notifications
- [ ] Calendar integration
- [ ] Image upload and optimization

---

## 🔐 Permissions & Security

Consider implementing:
- Custom permissions for club admins
- Event creator permissions
- System admin permissions
- API rate limiting
- File upload validation
- XSS protection
- CSRF tokens for non-API views

---

## 📝 Environment Variables

Consider moving sensitive data to environment variables:

```python
# settings.py
import os
from pathlib import Path

SECRET_KEY = os.getenv('SECRET_KEY', 'your-default-secret-key')
DEBUG = os.getenv('DEBUG', 'True') == 'True'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.getenv('DB_NAME', 'event_connect'),
        'USER': os.getenv('DB_USER', 'root'),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '3306'),
    }
}
```

---

## 📚 Additional Resources

- Django Documentation: https://docs.djangoproject.com/
- Django REST Framework: https://www.django-rest-framework.org/
- JWT Authentication: https://django-rest-framework-simplejwt.readthedocs.io/

---

## ⚠️ Important Notes

1. **Custom User Model**: The project uses a custom User model (`accounts.User`). This must be set before first migration.

2. **Migrations**: Always create migrations after model changes:
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

3. **Media Files**: In production, use a service like AWS S3 for media files.

4. **Database**: The current warning about database access is expected if you haven't configured the database yet.

---

## 🐛 Troubleshooting

### Issue: "Access denied for user 'root'@'localhost'"
**Solution**: Update database credentials in settings.py

### Issue: "No such table" errors
**Solution**: Run migrations: `python manage.py migrate`

### Issue: ImportError for models
**Solution**: Ensure all apps are in INSTALLED_APPS

### Issue: Admin CSS not loading
**Solution**: Run `python manage.py collectstatic`

---

Good luck with your Event Connect Backend project! 🚀
