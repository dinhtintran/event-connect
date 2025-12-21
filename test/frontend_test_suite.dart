/// Frontend Test Suite - Run all frontend tests in one command
/// 
/// Usage: flutter test test/frontend_test_suite.dart
/// 
/// This file imports and runs all frontend tests to provide
/// comprehensive coverage of the Flutter app.

import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'widget_test.dart' as widget_test;
import 'home_screen_test.dart' as home_screen_test;
import 'event_service_save_test.dart' as save_test;
import 'create_event_form_test.dart' as form_test;
import 'event_registration_test.dart' as registration_test;

void main() {
  group('Frontend Test Suite', () {
    group('App Entry Tests', () {
      widget_test.main();
    });

    group('Home Screen Tests', () {
      home_screen_test.main();
    });

    group('Saved Events Tests', () {
      save_test.main();
    });

    group('Create Event Form Tests', () {
      form_test.main();
    });

    group('Event Registration Tests', () {
      registration_test.main();
    });
  });
}
