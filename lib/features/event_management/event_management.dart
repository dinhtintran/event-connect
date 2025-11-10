/// Barrel export for event management feature.
/// 
/// Import this file to access all public APIs of the event management feature.
/// 
/// Example:
/// ```dart
/// import 'package:event_connect/features/event_management/event_management.dart';
/// ```

// Domain
export 'domain/models/event.dart';
export 'domain/models/event_registration.dart';
export 'domain/models/feedback.dart';
export 'domain/services/event_service.dart';

// Data
export 'data/api/event_api.dart';
export 'data/repositories/event_repository.dart';

// Presentation
export 'presentation/screens/home_screen.dart';
export 'presentation/screens/explore_screen.dart';
export 'presentation/screens/my_events_screen.dart';
export 'presentation/screens/event_detail_screen.dart';
export 'presentation/widgets/category_chip.dart';
export 'presentation/widgets/event_card_large.dart';
export 'presentation/widgets/event_list_item.dart';

