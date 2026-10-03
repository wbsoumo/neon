import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'main_navigation_screen.dart';
import 'splash_screen.dart';
import 'language_selection_screen.dart';

class AnimatedNeonSplashScreen extends StatefulWidget {
  const AnimatedNeonSplashScreen({super.key});

  @override
  State<AnimatedNeonSplashScreen> createState() => _AnimatedNeonSplashScreenState();
}

class _AnimatedNeonSplashScreenState extends State<AnimatedNeonSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bgGlowAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _taglineFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 0.2s - 0.8s: Background Glow Expansion
    _bgGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );

    // 0.5s - 1.2s: Logo Scale & Fade
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.55, curve: Curves.easeIn),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 1.0s - 1.6s: Brand Name Reveal (NEON BANK)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeIn),
      ),
    );

    // 1.4s - 2.0s: Secondary Tagline Reveal
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.9, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Perform initialization asynchronously and navigate smoothly
    _initializeAppAndNavigate();
  }

  Future<void> _initializeAppAndNavigate() async {
    final startTime = DateTime.now();

    // Perform Session & Language Check in background
    final prefsFuture = SharedPreferences.getInstance();
    final userFuture = ApiService.getSavedUserSession();

    final prefs = await prefsFuture;
    final hasSelectedLanguage = prefs.getBool('has_selected_language') ?? false;
    final savedUser = await userFuture;

    // Minimum display time for animation experience (2.2 seconds)
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remainingDelay = 2200 - elapsed;
    if (remainingDelay > 0) {
      await Future.delayed(Duration(milliseconds: remainingDelay));
    }

    if (!mounted) return;

    if (!hasSelectedLanguage) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LanguageSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    if (savedUser != null && savedUser.appId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MainNavigationScreen(user: savedUser),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD), // Premium off-white neutral background
      body: Stack(
        children: [
          // Background Glow Effect
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Center(
                child: Container(
                  width: 320 * _bgGlowAnimation.value,
                  height: 320 * _bgGlowAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.neonPink.withValues(alpha: 0.08 * _bgGlowAnimation.value),
                        const Color(0xFF0E1C36).withValues(alpha: 0.03 * _bgGlowAnimation.value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Main Animated Content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stage 2: Existing Application Logo Reveal
                    FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: Container(
                          width: 88,
                          height: 88,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0E1C36).withValues(alpha: 0.06),
                                blurRadius: 24,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: AppTheme.neonPink.withValues(alpha: 0.12),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Stage 3: Brand Name "NEON BANK" Reveal
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            "NEON BANK",
                            style: TextStyle(
                              color: AppTheme.darkNavy,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Stage 4: Security / Banking Identity Tagline
                          FadeTransition(
                            opacity: _taglineFadeAnimation,
                            child: const Text(
                              "Secure  •  Global  •  Digital Banking",
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Stage 5: Loading Indicator at Bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _taglineFadeAnimation,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.neonPink.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
