# 🔐 Authentication API Payload Reference

## Register Endpoint

### POST /api/accounts/register/

#### Request Payload Format
```json
{
  "username": "sang@gmail.com",
  "email": "sang@gmail.com",
  "password": "123456789",
  "password_confirm": "123456789",
  "role": "student",
  "first_name": "Sang",
  "last_name": "Nguyen"
}
```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `username` | string | ✅ | Username (usually same as email) |
| `email` | string | ✅ | Valid email address |
| `password` | string | ✅ | Password (min 8 characters) |
| `password_confirm` | string | ✅ | Must match password |
| `role` | string | ✅ | User role: `student`, `club_admin`, or `system_admin` |
| `first_name` | string | ✅ | User's first name |
| `last_name` | string | ❌ | User's last name (can be empty string) |

#### Role Values
```dart
- 'student'       // Sinh viên/Người dùng thông thường
- 'club_admin'    // Quản trị viên CLB
- 'system_admin'  // Quản trị viên hệ thống
```

#### Success Response (201 Created)
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "sang@gmail.com",
    "email": "sang@gmail.com",
    "first_name": "Sang",
    "last_name": "Nguyen",
    "role": "student",
    "is_active": true
  }
}
```

#### Error Response (400 Bad Request)
```json
{
  "username": ["This field is required."],
  "email": ["Enter a valid email address."],
  "password": ["This field is required."],
  "password_confirm": ["Passwords do not match."]
}
```

---

## Login Endpoint

### POST /api/accounts/token/

#### Request Payload Format
```json
{
  "username": "sang@gmail.com",
  "password": "123456789"
}
```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `username` | string | ✅ | Username or email |
| `password` | string | ✅ | User's password |

#### Success Response (200 OK)
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### Error Response (401 Unauthorized)
```json
{
  "detail": "No active account found with the given credentials"
}
```

---

## Token Refresh Endpoint

### POST /api/accounts/token/refresh/

#### Request Payload Format
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### Success Response (200 OK)
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

---

## Get User Info Endpoint

### GET /api/accounts/me/

#### Headers
```
Authorization: Bearer <access_token>
```

#### Success Response (200 OK)
```json
{
  "ok": true,
  "user": {
    "id": 1,
    "username": "sang@gmail.com",
    "email": "sang@gmail.com",
    "first_name": "Sang",
    "last_name": "Nguyen",
    "role": "student",
    "is_active": true,
    "date_joined": "2025-11-10T10:00:00Z"
  }
}
```

---

## Logout Endpoint

### POST /api/accounts/logout/

#### Request Payload Format
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### Headers
```
Authorization: Bearer <access_token>
```

#### Success Response (200 OK)
```json
{
  "detail": "Successfully logged out"
}
```

---

## Flutter Implementation

### Register Example
```dart
// In RegisterScreen
final payload = {
  'username': email,
  'email': email,
  'password': password,
  'password_confirm': confirmPassword,
  'role': 'student', // or 'club_admin', 'system_admin'
  'first_name': firstName,
  'last_name': lastName,
};

final resp = await authService.registerDetailed(payload: payload);
```

### Login Example
```dart
// In LoginScreen
final success = await authService.loginWithCredentials(
  username: email,
  password: password,
);
```

---

## Changes Made (Nov 10, 2025)

### ✅ Updated Files

1. **register_screen.dart**
   - Changed payload format from `display_name` to `first_name` + `last_name`
   - Added `password_confirm` field
   - Split full name into first and last name automatically

2. **auth_service.dart**
   - Updated `registerWithRole` method to use new payload format
   - Added name splitting logic

### 📋 Payload Mapping

| Old Format | New Format | Notes |
|------------|------------|-------|
| `display_name` | `first_name` + `last_name` | Auto-split by space |
| N/A | `password_confirm` | Added, must match password |
| `role` | `role` | Unchanged |
| `username` | `username` | Unchanged |
| `email` | `email` | Unchanged |
| `password` | `password` | Unchanged |

---

## Testing

### Test Register Flow
```bash
# 1. Run backend
python manage.py runserver

# 2. Run Flutter app
flutter run

# 3. Navigate to Register screen

# 4. Fill in form:
Name: Sang Nguyen
Email: sang@gmail.com
Password: 123456789
Confirm: 123456789
Role: Người dùng thông thường (student)

# 5. Check console for payload:
[RegisterScreen] payload: {
  username: sang@gmail.com,
  email: sang@gmail.com,
  password: 123456789,
  password_confirm: 123456789,
  role: student,
  first_name: Sang,
  last_name: Nguyen
}

# 6. Verify success:
- Should see success message
- Should redirect to home screen
- Should be logged in
```

---

## Error Handling

### Common Errors

#### 1. Password Mismatch
```json
{
  "password_confirm": ["Passwords do not match."]
}
```
**Frontend handles**: Check password == confirmPassword before submit

#### 2. Email Already Exists
```json
{
  "email": ["User with this email already exists."]
}
```
**Frontend displays**: Error message under email field

#### 3. Weak Password
```json
{
  "password": ["This password is too short. It must contain at least 8 characters."]
}
```
**Frontend displays**: Error message under password field

#### 4. Invalid Email
```json
{
  "email": ["Enter a valid email address."]
}
```
**Frontend validates**: Email format before submit

---

## Notes

- **username** field is typically the same as **email** for simplicity
- **first_name** and **last_name** are split automatically from full name input
- **password_confirm** is validated on both frontend and backend
- **role** must be one of: `student`, `club_admin`, `system_admin`
- All string fields should be trimmed before sending

---

**Updated**: November 10, 2025  
**Status**: ✅ Compatible with Backend API
