/// Application configuration constants.
class AppConfig {
  /// Base URL for backend API.
  /// Use 192.168.1.105 for LAN access (physical devices on same network)
  /// Use 10.0.2.2 for Android emulator (maps to host machine's localhost)
  /// Use 127.0.0.1 for iOS simulator or web
  static const String apiBaseUrl = 'http://127.0.0.1:8000/';
}

