import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../screens/home_screen.dart';

// ---------------- Header ----------------
class AppHeader extends StatelessWidget {
  final String title;
  final bool showBackArrow;
  final Widget? trailing;

  const AppHeader({
    Key? key,
    this.title = "BiTE Translator",
    this.showBackArrow = true,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // SafeArea ensures we don't draw under the notch/status bar
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false, // We only care about the top safe area for the header
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              if (showBackArrow)
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // Reduced padding slightly for better fit
                    child: Image.asset(
                      'assets/images/back_icon.png', 
                      width: 40, 
                      height: 40
                    ),
                  ),
                ),
              
              Image.asset(
                'assets/images/bite_icon.png', 
                width: 50, // Slightly adjusted for better alignment
                height: 60,
                fit: BoxFit.contain,
              ),
              
              const SizedBox(width: 10),
              
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold
                  ),
                  overflow: TextOverflow.ellipsis, // Prevents overflow on small screens
                ),
              ),
              
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Bottom Nav (ANDROID ONLY) ----------------
class BottomNavPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // iOS usually relies on swipe gestures or system bars, so we hide this.
    // If you WANT it on iOS, remove this line.
    if (Platform.isIOS) return const SizedBox.shrink(); 

    return Container(
      color: AppColors.secondary,
      child: SafeArea(
        top: false, // Only care about bottom safe area (home indicator)
        child: Container(
          height: 70, // Fixed height for consistency
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Better spacing
            children: [
              // Home Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Check if we are already on HomeScreen to avoid duplicate push
                    // We use ModalRoute to check the runtime type of the current page
                    final currentRoute = ModalRoute.of(context);
                    bool isAlreadyHome = currentRoute?.settings.name == '/' || 
                                         currentRoute?.settings.name == 'HomeScreen';
                    
                    // If your routing isn't named, we just pushAndRemoveUntil 
                    // which is the safest "Reset to Home" method.
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/home_page.png', 
                        width: 30, 
                        height: 30
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Home", 
                        style: TextStyle(color: Colors.white, fontSize: 12)
                      ),
                    ],
                  ),
                ),
              ),

              // Vertical Divider for visual separation
              Container(
                width: 1, 
                height: 40, 
                color: Colors.white24
              ),

              // Exit Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    // SystemNavigator.pop() minimizes the app on Android
                    SystemNavigator.pop();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/exit_icon.png', 
                        width: 30, 
                        height: 30
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Exit", 
                        style: TextStyle(color: Colors.white, fontSize: 12)
                      ),
                    ],
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