import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'game_level_screen.dart';
import '../home_screen.dart';

class WordGuessEntryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/wallpaperwordguess.png'), 
              fit: BoxFit.cover
            )
          ),
          child: Column(
            children: [
              // Back Arrow
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen())),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset('assets/images/back_icon.png', width: 40, height: 40),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Logo (Transparent placeholder)
              Image.asset(
                'assets/images/transparent.png', 
                width: 200, 
                height: 200, 
                errorBuilder: (c,e,s) => const SizedBox(height: 200, width: 200)
              ),
              
              const SizedBox(height: 10),
              
              // Start Button with Shadow
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameLevelScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 102, 0), 
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  // Added Shadow Properties
                  elevation: 10, // Lifts the button up
                  shadowColor: Colors.black, // Dark shadow to contrast with orange background
                ),
                child: const Text(
                  "Start Game", 
                  style: TextStyle(
                    fontSize: 20, 
                    color: AppColors.white,
                    // Optional: Added text shadow for better readability
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black26,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}