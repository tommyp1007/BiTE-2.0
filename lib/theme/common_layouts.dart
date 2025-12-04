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
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        bottom: 10,
      ),
      color: AppColors.primary,
      child: Row(
        children: [
          if (showBackArrow)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Image.asset('assets/images/back_icon.png', width: 40, height: 40),
              ),
            ),
          Image.asset('assets/images/bite_icon.png', width: 60, height: 70),
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

// ---------------- Bottom Nav (ANDROID ONLY) ----------------
class BottomNavPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) return SizedBox.shrink(); // ensure safety, no rendering on iOS

    return Container(
      color: AppColors.secondary,
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/home_page.png', width: 40, height: 40),
                      SizedBox(height: 4),
                      Text("Home", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () => SystemNavigator.pop(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/exit_icon.png', width: 40, height: 40),
                      SizedBox(height: 4),
                      Text("Exit", style: TextStyle(color: Colors.white, fontSize: 14)),
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
