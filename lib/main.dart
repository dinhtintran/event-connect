import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/routes.dart';
import 'src/auth/auth_service.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'pages/club_home_page.dart';
import 'pages/club_events_page.dart';
import 'package:dio/dio.dart';
import 'src/services/token_storage.dart';
import 'src/config.dart';
import 'src/services/token_interceptor.dart';
import 'src/services/auth_api.dart';
import 'src/services/auth_repository.dart';

void main() {
  runApp(const EventConnectApp());
}

class EventConnectApp extends StatelessWidget {
  const EventConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Prepare Dio + interceptor + repository so AuthService can use API-backed repo
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    final tokenStorage = TokenStorage();
    dio.interceptors.add(TokenInterceptor(tokenStorage: tokenStorage));
    final api = AuthApi(dio: dio);
    final repo = AuthRepository(api: api, tokenStorage: tokenStorage);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(repository: repo)),
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xE65C6BF0))),
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
        initialRoute: Routes.login,
        routes: {
          Routes.login: (_) => const LoginScreen(),
          Routes.register: (_) => const RegisterScreen(),
          Routes.home: (_) => const MainScreen(),
          Routes.clubHome: (_) => const ClubHomePage(),
          Routes.clubEvents: (_) => const ClubEventsPage(),
        },
      ),
    );
  }
}

