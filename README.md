# 🎓 Event Connect Backend

A comprehensive Django REST API backend for a university event management system with authentication, event registration, club management, and admin dashboard.

## ✨ Features

- 🔐 **JWT Authentication** with role-based access control
- 🎯 **Event Management** - Create, approve, and manage campus events  
- 🏢 **Club Management** - Student organization management
- 📝 **Registration System** - Event sign-ups with QR codes
- ⭐ **Feedback System** - Ratings and reviews
- 🔔 **Notifications** - Real-time user notifications
- 📊 **Admin Dashboard** - Statistics and analytics
- 🔍 **Search & Filter** - Advanced event discovery

## 🚀 Quick Start

### Installation

```bash
git checkout backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

## 📚 Full Documentation

- [**API Implementation**](API_IMPLEMENTATION.md) - Complete API reference (25+ endpoints)
- [**Models Documentation**](MODELS_DOCUMENTATION.md) - Database models
- [**Database Schema**](DATABASE_SCHEMA.md) - ER diagrams
- [**Quick Start Guide**](QUICK_START.md) - Detailed setup
- [**Summary**](SUMMARY.md) - Project completion status

## 🎯 API Endpoints (25+)

**Base URL**: `http://127.0.0.1:8000/api`

### Authentication
- `POST /accounts/register/` - Register
- `POST /accounts/login/` - Login (JWT)
- `GET /accounts/me/` - Current user

### Events (9 endpoints)
- `GET /events/` - List events
- `POST /events/{id}/register/` - Register for event
- `POST /events/{id}/feedback/` - Submit feedback
- And more...

### Clubs (3 endpoints)
- `GET /clubs/` - List clubs
- `POST /clubs/` - Create club

### Admin (6 endpoints)
- `GET /admin/stats/` - Dashboard
- `POST /approvals/{id}/approve/` - Approve event

See [API_IMPLEMENTATION.md](API_IMPLEMENTATION.md) for complete documentation.

## 🗄️ Database (13 Models)

- User, Club, ClubMembership
- Event, EventRegistration, EventApproval
- Feedback, Notification, ActivityLog
- And more...

## 🔐 User Roles

- **Student** - View & register for events
- **Club Admin** - Manage club events
- **System Admin** - Full access

## 🛠️ Tech Stack

- Django 5.2.7 + Django REST Framework
- JWT Authentication
- MySQL Database
- CORS Support

## ✅ Status

- **25+ API Endpoints**: ✅ Complete
- **13 Models**: ✅ Complete
- **Authentication**: ✅ Complete
- **Permissions**: ✅ Complete
- **Admin Dashboard**: ✅ Complete

**Version**: 1.0.0 | **Status**: Production Ready
