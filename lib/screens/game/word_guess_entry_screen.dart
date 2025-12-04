import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'game_level_screen.dart';
import '../home_screen.dart';

class WordGuessEntryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Use a gradient to mimic the "wallpaper" look (Orange Glow)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF9E40), // Lighter Orange (Top)
              Color(0xFFFF6E00), // Darker Orange (Bottom) - Matches the button style
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Back Arrow (Top Left)
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
                    child: Image.asset(
                      'assets/images/back_icon.png', 
                      width: 40, 
                      height: 40
                    ),
                  ),
                ),
              ),

              // 2. Centered Content (Logo & Button)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ensures content stays centered vertically
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- GAME LOGO ---
                    // This stays perfectly in the center relative to the column
                    Image.asset(
                      'assets/images/game_entry.png', 
                      width: 250, // Adjusted size for good visibility
                      height: 250, 
                      fit: BoxFit.contain,
                      // Fallback icon if image is missing
                      errorBuilder: (c, e, s) => const Icon(Icons.videogame_asset, size: 100, color: Colors.white),
                    ),
                    
                    const SizedBox(height: 50), // Spacing between Logo and Button
                    
                    // --- START BUTTON ---
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (_) => GameLevelScreen())
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // White button stands out on Orange
                        foregroundColor: const Color(0xFFFF6E00), // Orange text
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                        elevation: 8,
                        shadowColor: Colors.black45,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Start Game", 
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}