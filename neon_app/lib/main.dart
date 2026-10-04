import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/animated_splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
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
      title: 'Neon Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AnimatedNeonSplashScreen(),
    );
  }
}
