import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(const YerideApp());
}

class YerideApp extends StatelessWidget {
  const YerideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YɛRide',
      theme: ThemeData(
        primaryColor: const Color(0xFFFFC107),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFFC107),
          secondary: const Color(0xFFFFC107),
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
