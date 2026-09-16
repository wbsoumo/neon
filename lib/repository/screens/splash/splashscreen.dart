import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:blinkit_series/domain/constants/appcolors.dart';
import 'package:blinkit_series/repository/screens/login/loginscreen.dart';
import 'package:blinkit_series/repository/services/api_service.dart';
import 'package:blinkit_series/repository/widgets/uihelper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );

      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 3),
          );
          // Resolve nearest dark store automatically during splash initialization
          await ApiService.fetchSelectedStore(
            lat: pos.latitude,
            lng: pos.longitude,
            forceRefresh: true,
            isManual: false,
          );
        } else {
          // If no GPS permission yet, resolve store from saved coords or default
          await ApiService.fetchSelectedStore(forceRefresh: false);
        }
      } else {
        await ApiService.fetchSelectedStore(forceRefresh: false);
      }
    } catch (e) {
      debugPrint("Splash location resolution error: $e");
      await ApiService.fetchSelectedStore(forceRefresh: false);
    }

    // Ensure minimum 2.5 second splash display for smooth brand transition
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remaining = 2500 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: AppColors.scaffoldbackgroud,
     body: Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
         UiHelper.CustomImage(img: "image 1 (1).png"),
       ],),
     ),
   );
  }
}