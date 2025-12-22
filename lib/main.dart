import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import 'package:event_connect/app_routes.dart';
import 'package:event_connect/core/config/app_config.dart';
import 'package:event_connect/core/interceptors/token_interceptor.dart';
import 'package:event_connect/core/navigation/main_screen.dart';
import 'package:event_connect/features/authentication/authentication.dart';
import 'package:event_connect/features/event_creation/event_creation.dart';
import 'package:event_connect/features/event_approval/event_approval.dart';
import 'package:event_connect/features/event_approval/presentation/screens/event_management_screen.dart';
import 'package:event_connect/features/profile/presentation/screens/profile_screen.dart';
import 'package:event_connect/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/data/repositories/event_repository.dart';
import 'package:event_connect/features/event_management/domain/services/event_service.dart';
// Admin User/Event Management (new implementation)
import 'package:event_connect/features/admin/data/api/admin_api.dart';
import 'package:event_connect/features/admin/data/repositories/admin_repository.dart' as admin_mgmt;
import 'package:event_connect/features/admin/domain/services/admin_service.dart' as admin_mgmt;

// Admin Dashboard (old implementation for stats/activities)
import 'package:event_connect/features/admin_dashboard/domain/services/admin_service.dart' as admin_dash;
import 'package:event_connect/features/admin_dashboard/presentation/screens/admin_home_screen.dart';
import 'package:event_connect/features/admin_dashboard/presentation/screens/admin_user_management_screen.dart';
import 'package:event_connect/features/admin_dashboard/presentation/screens/admin_event_management_screen.dart';
import 'package:event_connect/features/admin_dashboard/presentation/screens/admin_reports_screen.dart';

void main() {
  runApp(const EventConnectApp());
}

class EventConnectApp extends StatelessWidget {
  const EventConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Prepare Dio + interceptor + repository so AuthService can use API-backed repo
    final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
    final tokenStorage = TokenStorage();
    dio.interceptors.add(TokenInterceptor(tokenStorage: tokenStorage));
    
    // Auth
    final authApi = AuthApi(dio: dio);
    final authRepo = AuthRepository(api: authApi, tokenStorage: tokenStorage);
    
    // Event Management
    final eventApi = EventApi(dio: dio);
    final eventRepo = EventRepository(api: eventApi);
    
    // Admin User/Event Management (new)
    final adminApi = AdminApi(dio: dio);
    final adminMgmtRepo = admin_mgmt.AdminRepository(api: adminApi);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(repository: authRepo)),
        ChangeNotifierProvider(create: (_) => EventService(repository: eventRepo)),
        // Admin Management Service (for user/event CRUD operations)
        ChangeNotifierProvider<admin_mgmt.AdminService>(
          create: (_) => admin_mgmt.AdminService(repository: adminMgmtRepo),
        ),
        // Admin Dashboard Service (for stats and activities)
        ChangeNotifierProvider<admin_dash.AdminService>(
          create: (_) => admin_dash.AdminService(),
        ),
      ],
      child: MaterialApp(
        title: 'Event Connect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // primary color tuned to match the mock's bluish accent
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C6BF0)),
          primaryColor: const Color(0xFF5C6BF0),
          scaffoldBackgroundColor: Colors.white,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xE65C6BF0)) ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFF5C6BF0),
              foregroundColor: Colors.white,
              elevation: 3,
            ),
          ),
          // cardTheme omitted for SDK compatibility; individual Cards can set shape if needed
        ),
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const MainScreen(),
          AppRoutes.clubHome: (_) => const ClubHomePage(),
          AppRoutes.clubEvents: (_) => const ClubEventsPage(),
          AppRoutes.clubStatistics: (_) => const ClubStatisticsScreen(),
          AppRoutes.clubStatisticsDetail: (_) => const ClubStatisticsDetailScreen(),
          AppRoutes.approval: (_) => const ApprovalScreen(), // Deprecated: kept for backward compatibility
          AppRoutes.eventManagement: (_) => const EventManagementScreen(),
          AppRoutes.admin: (_) => const AdminHomeScreen(),
          AppRoutes.adminReports: (_) => const AdminReportsScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.notifications: (_) => const NotificationsScreen(),
          '/admin/users': (_) => const AdminUserManagementScreen(),
          '/admin/events': (_) => const AdminEventManagementScreen(),
        },
      ),
    );
  }
}

