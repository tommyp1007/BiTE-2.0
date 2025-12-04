import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Import
import '../theme/app_colors.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Remove the static Native Splash immediately when this widget builds.
    // Since this widget's background is also green, the user won't notice the switch.
    FlutterNativeSplash.remove(); 

    // 2. Setup Animation Controller (2 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 3. Fade In (Opacity 0 -> 1)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // 4. Scale Up (Size 0.8 -> 1.0 with a bounce)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // 5. Start Animation
    _controller.forward();

    // 6. Navigate to Home after 3 seconds total
    Timer(const Duration(seconds: 3), () {
      if (mounted) { // Check mounted to prevent errors if user leaves app
        Navigator.of(context).pushReplacement(
          // Custom PageRoute for smooth Fade Transition to Home
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Ensure this matches native splash color
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your Logo
                Image.asset(
                  'assets/images/bite_icon2_bright.png',
                  width: 150,
                  height: 150,
                  // Handle error if image is missing so app doesn't crash
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.translate, size: 100, color: Colors.white);
                  },
                ),
                const SizedBox(height: 20),
                // App Title
                const Text(
                  "BiTE Translator",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}