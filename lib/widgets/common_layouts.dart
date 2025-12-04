import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../screens/home_screen.dart';

// Matches the header layout in activity_main.xml, activity_dictionary_meaning.xml, etc.
class AppHeader extends StatelessWidget {
  final String title;
  final bool showBackArrow;
  final VoidCallback? onBackCallback;
  final Widget? trailing; // For login/logout button

  const AppHeader({
    Key? key, 
    this.title = "BiTE Translator", 
    this.showBackArrow = true,
    this.onBackCallback,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      color: AppColors.primary,
      child: Row(
        children: [
          if (showBackArrow)
            GestureDetector(
              onTap: onBackCallback ?? () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.all(16.0), // XML layout_margin="16dp"
                child: Image.asset('assets/images/back_icon.png', width: 40, height: 40),
              ),
            ),
          
          Image.asset('assets/images/bite_icon2_bright.png', width: 60, height: 70, fit: BoxFit.contain),
          SizedBox(width: 8), // layout_marginEnd="8dp"
          
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppColors.white, fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),
          
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// Matches the Footer layout in activity_main.xml, activity_vocabulary_learning.xml, etc.
class BottomNavPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      padding: EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Home Button
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => HomeScreen()), 
                (route) => false
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/home_page.png', width: 60, height: 60),
                  Text("Home", style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // Exit Button
          Expanded(
            child: GestureDetector(
              onTap: () => SystemNavigator.pop(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/exit_icon.png', width: 60, height: 60),
                  Text("Exit", style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}