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
import 'package:event_connect/features/admin_dashboard/admin_dashboard.dart';
import 'package:event_connect/features/profile/presentation/screens/profile_screen.dart';
import 'package:event_connect/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/data/repositories/event_repository.dart';
import 'package:event_connect/features/event_management/domain/services/event_service.dart';

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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(repository: authRepo)),
        ChangeNotifierProvider(create: (_) => EventService(repository: eventRepo)),
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
          AppRoutes.approval: (_) => const ApprovalScreen(),
          AppRoutes.admin: (_) => const AdminHomeScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.notifications: (_) => const NotificationsScreen(),
        },
      ),
    );
  }
}

