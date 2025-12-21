# Testing Guide - Event Connect

Hướng dẫn chạy tất cả test ở local và hiểu CI/CD pipeline.

---

## 🚀 Quick Start

### Chạy tất cả test (Frontend + Backend) ở local trước khi push:

```bash
make ci-test-local
```

Điều này sẽ chạy:
1. Cleanup artifacts
2. Flutter linting (analyzer)
3. Frontend tests (11 tests)
4. Backend tests (Django)
5. Python linting

---

## 📱 Frontend Testing

### Chạy tất cả Flutter tests:
```bash
flutter test test/frontend_test_suite.dart
```

### Chạy test riêng từng file:
```bash
# App entry point
flutter test test/widget_test.dart

# Home screen rendering + error
flutter test test/home_screen_test.dart

# Saved events toggle logic
flutter test test/event_service_save_test.dart

# Create event form validation
flutter test test/create_event_form_test.dart

# Event registration/cancel logic
flutter test test/event_registration_test.dart
```

### Chạy tất cả test + coverage:
```bash
flutter test --coverage test/frontend_test_suite.dart
```

### Flutter analyzer (linting):
```bash
flutter analyze
```

---

## 🔧 Backend Testing

### Chạy Django unit tests:
```bash
cd event_connect_backend
python manage.py test
```

**Lưu ý:** Test dùng SQLite để tránh MySQL permission issues.

### Chạy manual API smoke test (server phải chạy):
```bash
# Terminal 1: Start server
cd event_connect_backend
python manage.py runserver

# Terminal 2: Run API tests
cd event_connect_backend
python test_apis.py
```

### Python linting (kiểm tra code quality):
```bash
cd event_connect_backend
pip install pylint
pylint accounts clubs event_management notifications --disable=C,W
```

---

## 📊 Makefile Commands

```bash
# Show all available commands
make help

# Frontend only
make test-frontend
make lint-frontend

# Backend only
make test-backend
make lint-backend
make test-backend-api   # Requires server running

# All testing
make test               # Frontend + Backend tests
make lint              # All linters
make test-all          # lint + test (comprehensive)

# Development
make run-app            # Start Flutter app
make run-backend        # Start Django server

# Cleanup
make clean              # Remove artifacts & cache

# CI Simulation (LOCAL)
make ci-test-local      # What GitHub Actions will run
```

---

## 🔄 CI/CD Pipeline (GitHub Actions)

Khi push lên GitHub, tự động chạy `.github/workflows/test.yml`:

### Chạy trên mỗi push:
- **branches**: main, develop, feature/*
- **jobs**:
  1. **Flutter Tests**: analyzer + 11 test cases
  2. **Django Tests**: migrations + unit tests
  3. **Linting**: code quality check

### Status Badge:
Bạn có thể thêm vào README:
```markdown
![CI Tests](https://github.com/YOUR_ORG/event_connect/actions/workflows/test.yml/badge.svg)
```

---

## 🧪 Test Coverage

### Frontend (Flutter):
| Test File | Tests | Coverage |
|-----------|-------|----------|
| widget_test.dart | 1 | App entry |
| home_screen_test.dart | 2 | Home render + error |
| event_service_save_test.dart | 2 | Save/unsave logic |
| create_event_form_test.dart | 2 | Form validation |
| event_registration_test.dart | 4 | Register/cancel logic |
| **TOTAL** | **11** | **Core flows** |

### Backend (Django):
- Event CRUD ✅
- User registration ✅ (in accounts/tests.py)
- Event registration flow ✅
- Saved events ✅
- Club admin permissions ✅

---

## ✅ Testing Checklist Before Push

- [ ] `make ci-test-local` passes locally
- [ ] No new linting errors
- [ ] Test output shows all tests pass
- [ ] No uncommitted changes to test files
- [ ] Backend server can start: `python manage.py runserver`
- [ ] Flutter app builds: `flutter run`

---

## 🐛 Troubleshooting

### Flutter test fails with "cannot find package"
```bash
flutter pub get
flutter pub upgrade
```

### Django test fails with MySQL error
- Tests use SQLite automatically (check settings.py)
- If error: `rm -f event_connect_backend/test_db.sqlite3`

### Test database locked
```bash
cd event_connect_backend
rm -f db.sqlite3 test_db.sqlite3
python manage.py migrate
```

### GitHub Actions fails but local passes
- Check Python version matches (3.12)
- Ensure requirements.txt is up to date
- Check Flutter version (3.9.2)

---

## 📝 Adding New Tests

### Frontend (Flutter):
1. Create file: `test/feature_name_test.dart`
2. Import test suite in `test/frontend_test_suite.dart`
3. Run: `flutter test test/feature_name_test.dart`
4. Add to CI workflow (auto-runs via suite)

### Backend (Django):
1. Add test class to app's `tests.py`
2. Run: `cd event_connect_backend && python manage.py test app_name`
3. CI auto-runs: `python manage.py test`

---

## 🎯 Test Goals

- **Smoke Tests**: App builds & basic flows work
- **Unit Tests**: Model logic, business rules
- **Integration**: API endpoints + database
- **Regression**: Catch bugs after refactoring
- **Performance**: Catch slowdowns early

---

## 📞 Questions?

- **Flutter Testing**: [flutter.dev/testing](https://flutter.dev/testing)
- **Django Testing**: [django docs](https://docs.djangoproject.com/en/stable/topics/testing/)
- **GitHub Actions**: [actions docs](https://docs.github.com/en/actions)
