import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'services/notification_service.dart';
import 'services/connectivity_service.dart';
import 'widgets/connectivity_wrapper.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA6DjNT03SYaan6WGjwvMy6dKqhUFdPxtw",
        authDomain: "yeride-e8966.firebaseapp.com",
        databaseURL: "https://yeride-e8966-default-rtdb.firebaseio.com",
        projectId: "yeride-e8966",
        storageBucket: "yeride-e8966.firebasestorage.app",
        messagingSenderId: "33526722996",
        appId: "1:33526722996:web:3dab236173fab4732802e1",
        measurementId: "G-T8M92DQRQ0",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  if (!kIsWeb) {
    await NotificationService().initialize();
  }

  // Start connectivity monitoring before the first frame is drawn
  await ConnectivityService.instance.init();

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
      // ConnectivityWrapper sits outside every route so the banner
      // persists across all navigation pushes and replacements.
      home: const ConnectivityWrapper(
        child: SplashScreen(),
      ),
    );
  }
}
