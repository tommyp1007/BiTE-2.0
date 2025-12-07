import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'game_level_screen.dart';
import '../home_screen.dart';

class WordGuessEntryScreen extends StatelessWidget {
  
  // --- UPDATED DIALOG DESIGN (Clear & Readable) ---
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0), // Modern rounded corners
          ),
          elevation: 10,
          backgroundColor: Colors.white, // Force White background for maximum clarity
          child: Container(
            padding: const EdgeInsets.all(24.0),
            constraints: const BoxConstraints(maxWidth: 400), // proper width on tablets
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content height
              children: [
                // 1. Large Icon for Visual Context
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6E00).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded, // "Idea" or "Hint" icon
                    color: Color(0xFFFF6E00),
                    size: 48,
                  ),
                ),
                
                const SizedBox(height: 20),

                // 2. Clear Title
                const Text(
                  "Game Info",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // Dark text for visibility
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // 3. Readable Body Text
                const Text(
                  "Uncover the Bidayuh word behind each figure. Use hints wisely to crack the puzzle!",
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5, // Better line spacing for readability
                    color: Colors.black54, // Soft black for comfortable reading
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // 4. Full Width Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6E00), // App Orange
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Got it!",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                                width: 280, 
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
                      color: Colors.black.withOpacity(0.05), 
                    ),
                    child: Image.asset(
                      'assets/images/back_icon.png', 
                      width: 40, 
                      height: 40,
                      // Fallback icon if image is missing
                      errorBuilder: (c, e, s) => const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),

              // 3. HELP / QUESTION MARK (Fixed Top Right)
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => _showHelpDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.05), // Matches the back button style
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded, 
                      color: Colors.white, 
                      size: 40
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