git checkout backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py runserver

# EventConnect 📱

**EventConnect** is a modern mobile application built with Flutter that helps users discover, create, and manage events seamlessly. Whether you're organizing a conference, meetup, concert, or social gathering, EventConnect provides the tools to connect people and create memorable experiences.

## ✨ Features



## 🚀 Getting Started

### Prerequisites

Before running this project, make sure you have the following installed:

- **Flutter SDK**: Version 3.9.2 or higher
- **Dart SDK**: Version 3.9.2 or higher
- **Android Studio** (for Android development) or **Xcode** (for iOS development)
- **Git**: For cloning the repository
- A physical device or emulator for testing

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/event_connect.git
   cd event_connect
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter installation**
   ```bash
   flutter doctor
   ```
   Make sure all checkmarks are green. Fix any issues reported.

4. **Run the application**

    - For Android/iOS:
      ```bash
      flutter run
      ```

    - For a specific device:
      ```bash
      flutter devices
      flutter run -d <device_id>
      ```

    - For web:
      ```bash
      flutter run -d chrome
      ```

    - For Windows:
      ```bash
      flutter run -d windows
      ```

### Building for Production

- **Android APK**:
  ```bash
  flutter build apk --release
  ```

- **Android App Bundle**:
  ```bash
  flutter build appbundle --release
  ```

- **iOS**:
  ```bash
  flutter build ios --release
  ```

- **Web**:
  ```bash
  flutter build web --release
  ```

## 📋 Project Structure

```
event_connect/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── models/                # Data models
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable widgets
│   ├── services/              # API and business logic
│   └── utils/                 # Helper functions
├── assets/                    # Images, fonts, etc.
├── test/                      # Unit and widget tests
└── pubspec.yaml              # Dependencies
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.9.2
- **Language**: Dart 3.9.2
- **State Management**:
- **Backend**:
- **Database**:
- **Authentication**:

## 📊 Development Timeline (5 Weeks)

| Week | Tasks | Status | Deliverables | Team Members | Notes |
|------|-------|--------|--------------|--------------|-------|
| **Week 1**<br>*(Oct 8 - Oct 13)* | - Project setup and initialization<br>- Design system and UI/UX mockups<br>- Setup version control (Git)<br>- Define architecture and folder structure<br>- Create data models | 🟡 In Progress | - Project repository<br>- Design documentation<br>- Architecture diagram<br>- Basic app skeleton | All team members | Initial planning phase |
| **Week 2**<br>*(Oct 14 - Oct 20)* | - Implement authentication (Login/Register)<br>- Setup database schema<br>- Create home screen and navigation<br>- Build event list/grid view<br>- Implement event detail screen | ⚪ Not Started | - Authentication module<br>- Database setup<br>- Core screens<br>- Navigation flow | Frontend & Backend teams | Focus on core features |
| **Week 3**<br>*(Oct 21 - Nov 27)* | - Implement event creation/editing<br>- Add event search and filtering<br>- Integrate map for location features<br>- Build user profile screen<br>- Setup push notifications | ⚪ Not Started | - Event CRUD operations<br>- Search functionality<br>- Map integration<br>- Profile management | All teams | Major features week |
| **Week 4**<br>*(Nov 28 - Nov 3)* | - Implement ticketing system<br>- Add social features (comments, likes)<br>- Real-time updates integration<br>- Image upload and storage<br>- Testing and bug fixes | ⚪ Not Started | - Ticketing module<br>- Social features<br>- Image handling<br>- Test reports | All teams | Feature completion |
| **Week 5**<br>*(Nov 4 - Nov 10)* | - Final testing and QA<br>- Performance optimization<br>- Documentation completion<br>- Deployment preparation<br>- Project presentation prep | ⚪ Not Started | - Final application<br>- Complete documentation<br>- Deployment package<br>- Presentation slides | All teams | Final polishing |

### Status Legend
- 🟢 **Completed**: Task finished and verified
- 🟡 **In Progress**: Currently being worked on
- 🔴 **Blocked**: Waiting on dependencies or issues
- ⚪ **Not Started**: Scheduled for future

## 📝 Weekly Reports

### Week 1 Report (Oct 8 - Oct 13)
- **Achievements**:
    - Project initialized with Flutter
    - Repository created and team access granted
    - Initial README documentation completed
- **Challenges**: TBD
- **Next Steps**: Complete UI/UX design and finalize architecture

### Week 2 Report (Oct 14 - Oct 20)
- **Achievements**: TBD
- **Challenges**: TBD
- **Next Steps**: TBD

### Week 3 Report (Oct 21 - Nov 27)
- **Achievements**: TBD
- **Challenges**: TBD
- **Next Steps**: TBD

### Week 4 Report (Nov 28 - Nov 3)
- **Achievements**: TBD
- **Challenges**: TBD
- **Next Steps**: TBD

### Week 5 Report (Nov 4 - Nov 10)
- **Achievements**: TBD
- **Challenges**: TBD
- **Next Steps**: TBD

## 🧪 Testing

Run unit tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test
```

Run tests with coverage:
```bash
flutter test --coverage
```


### Coding Standards
- Follow Dart style guidelines
- Write meaningful commit messages
- Add comments for complex logic
- Write unit tests for new features
- Update documentation as needed

## 👥 Team Members

| Name | Student ID | Contact |
|------|------|---------|
| Tran Dinh Tin | 123210153 | learning.dinhtin@gmail.com |
| Tran Van Dinh Sang | 123210147 | dinhsang2313@gmail.com |
| Thai Nam Hung | 123210057 | hungthai3113@gmail.com |
| Nguyen Thi Yen Nhi | 123210143 | yennhinguyen22022003@gmail.com |

## 🔗 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Material Design Guidelines](https://material.io/design)
- [Firebase Documentation](https://firebase.google.com/docs)

## 📱 Screenshots

*Coming soon...*

---

**Last Updated**: October 12, 2025  
**Version**: 1.0.0  
**Status**: 🟡 In Development
