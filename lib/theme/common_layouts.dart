import 'dart:io'; // Required for exit(0) on iOS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../screens/home_screen.dart';

// Matches the header layout pattern
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
        top: MediaQuery.of(context).padding.top + 10, // Handle top safe area manually if needed, or rely on Scaffold
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
          
          Image.asset('assets/images/bite_icon2_bright.png', width: 60, height: 70, fit: BoxFit.contain),
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

// Fixed Bottom Panel
class BottomNavPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // We wrap in a generic container for background color
    return Container(
      color: AppColors.secondary,
      child: SafeArea(
        // SafeArea ensures this doesn't get cut off by the iPhone Home indicator
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
                    // Navigate to Home and clear stack
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
                      SystemNavigator.pop();
                    } else if (Platform.isIOS) {
                      // iOS doesn't allow SystemNavigator.pop(). 
                      // exit(0) kills the process. Note: Apple guidelines discourage this, 
                      // but it is the only way to programmatically "close" the app.
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