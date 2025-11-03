import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/club_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo Firebase cho Flutter Web
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA6QVAe6TRaCJz9TNTW475N1XZU65dG28M",
      authDomain: "eventconnect-a62ad.firebaseapp.com",
      projectId: "eventconnect-a62ad",
      // ⚠️ Fix lỗi: storageBucket phải là ".appspot.com" (không phải ".firebasestorage.app")
      storageBucket: "eventconnect-a62ad.appspot.com",
      messagingSenderId: "638027325119",
      appId: "1:638027325119:web:434c0277ddc4d8c8abf00a",
      measurementId: "G-PQCFJ3T5C3",
    ),
  );

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Connect',
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const ClubHomePage(),
    );
  }
}
