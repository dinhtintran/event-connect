import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const EventConnectApp());
}

class EventConnectApp extends StatelessWidget {
  const EventConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5669FF),
          primary: const Color(0xFF5669FF),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF120D26)),
          titleTextStyle: TextStyle(
            color: Color(0xFF120D26),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
