import 'package:flutter/material.dart';

import '../../core/storage/user_prefs.dart';
import '../../service/auth_service.dart';
import '../auth/auth_screen.dart';
import '../home/main_home_screen.dart';
import '../onboarding/nickname_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final isSetup = await UserPrefs.isSetupComplete();
    if (!mounted) return;

    Widget destination;
    if (!isSetup) {
      destination = const NicknameScreen();
    } else {
      final isLoggedIn = await AuthService().isLoggedIn();
      destination = isLoggedIn ? const MainHomeScreen() : const AuthScreen();
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pastelRedPink3 = Color(0xFFFFEBEE);
    const Color pastelRedPink2 = Color(0xFFF8A8B8);
    const Color pastelRedPink1 = Color(0xFFF06292);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [pastelRedPink1, pastelRedPink2, pastelRedPink3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 18),
              child: child,
            ),
          ),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/splash_mascots.png',
                width: screenWidth * 0.75,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 42),
                child: Image.asset(
                  'assets/images/allerview_logo_transparent.png',
                  width: screenWidth * 0.68,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '개인 맞춤형 알레르기 위험 식재료 안내 서비스',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
