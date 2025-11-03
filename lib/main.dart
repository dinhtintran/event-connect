import 'package:flutter/material.dart';
import 'screens/admin/admin_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventConnect Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Text',
      ),
      home: const AdminHomeScreen(),
    );
  }
}
