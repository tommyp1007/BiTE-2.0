import 'dart:io'; // 1. CRITICAL IMPORT: This is required for exit(0) to work on iOS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemNavigator on Android
import '../theme/app_colors.dart';
import '../screens/home_screen.dart';

// --- App Header ---
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
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10, 
        left: 10,
        right: 10,
        bottom: 10
      ),
      color: AppColors.primary,
      child: Row(
        children: [
          if (showBackArrow)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset('assets/images/back_icon.png', width: 40, height: 40),
              ),
            ),
          
          Image.asset('assets/images/bite_icon.png', width: 60, height: 70, fit: BoxFit.contain),
          SizedBox(width: 8), 
          
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),
          
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// --- Bottom Panel (Fixed for iOS) ---
class BottomNavPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: SafeArea(
        top: false, 
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Home Button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to Home and remove all previous routes to prevent back button loops
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (_) => HomeScreen()), 
                      (route) => false
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/home_page.png', width: 40, height: 40, fit: BoxFit.scaleDown),
                      SizedBox(height: 4),
                      Text("Home", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              
              // Exit Button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (Platform.isAndroid) {
                      // Standard Android exit
                      SystemNavigator.pop();
                    } else if (Platform.isIOS) {
                      // iOS FORCE EXIT
                      // Apple does not support "SystemNavigator.pop".
                      // We must use exit(0) from 'dart:io' to kill the process.
                      exit(0);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/exit_icon.png', width: 40, height: 40, fit: BoxFit.scaleDown),
                      SizedBox(height: 4),
                      Text("Exit", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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