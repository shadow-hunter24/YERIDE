import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
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
