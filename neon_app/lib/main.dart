import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/animated_splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    
    // Set foreground notification presentation options so alerts show heads-up banners when app is open
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("[FCM Foreground Message] Title: ${message.notification?.title}, Body: ${message.notification?.body}");
    });
  } catch (e) {
    debugPrint("[Firebase] Init error: $e");
  }
  runApp(const NeonFinanceApp());
}

class NeonFinanceApp extends StatelessWidget {
  const NeonFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AnimatedNeonSplashScreen(),
    );
  }
}
