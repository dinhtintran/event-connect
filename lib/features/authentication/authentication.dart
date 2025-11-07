/// Barrel export for authentication feature.
/// 
/// Import this file to access all public APIs of the authentication feature.
/// 
/// Example:
/// ```dart
/// import 'package:event_connect/features/authentication/authentication.dart';
/// ```

// Domain
export 'domain/models/user.dart';
export 'domain/services/auth_service.dart';

// Data
export 'data/api/auth_api.dart';
export 'data/repositories/auth_repository.dart';
export 'data/storage/token_storage.dart';

// Presentation
export 'presentation/screens/login_screen.dart';
export 'presentation/screens/register_screen.dart';

