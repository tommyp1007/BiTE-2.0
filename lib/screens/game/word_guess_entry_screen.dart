import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'game_level_screen.dart';
import '../home_screen.dart';

class WordGuessEntryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Use a gradient to mimic the "wallpaper" look (Orange Glow)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF9E40), // Lighter Orange (Top)
              Color(0xFFFF6E00), // Darker Orange (Bottom)
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 1. MAIN CONTENT (Scrollable & Centered)
              // LayoutBuilder allows us to calculate screen height for centering
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      // Ensure the content is at least as tall as the screen
                      // so the Center widget works
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        // Limit width for Tablets/Web so it doesn't look stretched
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // --- GAME LOGO ---
                              Image.asset(
                                'assets/images/game_entry.png', 
                                width: 280, // Slightly larger for impact
                                height: 280, 
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(Icons.videogame_asset, size: 120, color: Colors.white),
                              ),
                              
                              const SizedBox(height: 60), // Spacing
                              
                              // --- START BUTTON ---
                              SizedBox(
                                width: double.infinity, // Fill the limited width container
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushReplacement(
                                    context, 
                                    MaterialPageRoute(builder: (_) => GameLevelScreen())
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFFF6E00),
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    elevation: 8,
                                    shadowColor: Colors.black45,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    "START GAME", 
                                    style: TextStyle(
                                      fontSize: 24, 
                                      fontWeight: FontWeight.w900, // Extra bold
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Extra padding at bottom to prevent being too close to edge
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 2. BACK ARROW (Fixed Top Left)
              Positioned(
                top: 10,
                left: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (_) => HomeScreen())
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Optional: subtle background to make it visible if content scrolls behind
                      color: Colors.black.withOpacity(0.05), 
                    ),
                    child: Image.asset(
                      'assets/images/back_icon.png', 
                      width: 40, 
                      height: 40
                    ),
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