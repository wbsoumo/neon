import 'package:flutter/material.dart';
import 'screens/animated_splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
