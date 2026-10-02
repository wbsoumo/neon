import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/api_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedUser = await ApiService.getSavedUserSession();
  runApp(NeonFinanceApp(initialUser: savedUser));
}

class NeonFinanceApp extends StatelessWidget {
  final UserModel? initialUser;
  const NeonFinanceApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: (initialUser != null && initialUser!.appId.isNotEmpty)
          ? MainNavigationScreen(user: initialUser!)
          : const SplashScreen(),
    );
  }
}
