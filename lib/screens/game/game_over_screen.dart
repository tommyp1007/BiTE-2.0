import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart';
import 'play_game_screen.dart';
import 'game_level_screen.dart';

class GameOverScreen extends StatefulWidget {
  final int level;
  const GameOverScreen({Key? key, required this.level}) : super(key: key);

  @override
  _GameOverScreenState createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SharedPreferencesHelper _prefs = SharedPreferencesHelper();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _playFinishSound();
  }

  void _playFinishSound() async {
    await _audioPlayer.play(AssetSource('audio/finish.mp3'));
  }

  String _getDifficultyMode(int level) {
    if (level <= 5) return "Easy";
    if (level <= 10) return "Medium";
    return "Hard";
  }

  // Logic from Java: getNextLevel
  int _getNextLevel(int level) {
    if (level <= 5) return 6;      // Go to Medium
    if (level <= 10) return 11;    // Go to Hard
    return level;                  // Already at hardest (15)
  }

  void _handleNextLevel() async {
    int nextLevel = _getNextLevel(widget.level);
    String nextDifficulty = _getDifficultyMode(nextLevel);

    // 1. Update Local Prefs
    await _prefs.setCurrentLevel(nextLevel);
    await _prefs.saveDifficulty(nextDifficulty);

    int currentUnlocked = await _prefs.getUnlockedLevel();
    if (nextLevel > currentUnlocked) {
      await _prefs.setUnlockedLevel(nextLevel);
    }

    // 2. Update Firestore (Matches Java update logic)
    User? user = _auth.currentUser;
    if (user != null) {
      _db.collection('users').doc(user.uid).update({
        'currentLevel': nextLevel,
        'difficulty': nextDifficulty,
        'unlockedLevel': nextLevel > currentUnlocked ? nextLevel : currentUnlocked,
      }).catchError((e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update game state")));
        }
      });
    }

    if (mounted) {
      // Replace current screen so user can't back into it
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => PlayGameScreen(level: nextLevel))
      );
    }
  }

  void _handleExit() {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameLevelScreen()));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String diffMode = _getDifficultyMode(widget.level);
    bool isLastLevel = widget.level >= 15;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // --- UPDATED HEADER (Centered Title) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.primary,
              child: Stack(
                alignment: Alignment.center, // This ensures the Title/Icon is dead center
                children: [
                  // 1. Back Button (Aligned to the Left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _handleExit,
                      child: Image.asset('assets/images/back_icon.png', width: 40, height: 40),
                    ),
                  ),

                  // 2. Title & Icon (Centered in the Stack)
                  Row(
                    mainAxisSize: MainAxisSize.min, // Shrink row to fit content
                    children: [
                      Image.asset(
                        'assets/images/bite_icon.png', 
                        width: 60, 
                        height: 70, 
                        fit: BoxFit.contain
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "BiTE Translator",
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 23, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Main Content (Trophy & Text) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Trophy Image
                    Expanded(
                      child: Center(
                        child: Image.asset('assets/images/trophy.png', width: 300, height: 300),
                      ),
                    ),
                    
                    // Congratulation Text
                    Text(
                      "Congratulations!\nYou've completed the $diffMode Mode!", 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                    SizedBox(height: 30),
                    
                    // --- Buttons ---
                    if (!isLastLevel)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleNextLevel, 
                          child: Text("Next Level Mode", style: TextStyle(fontSize: 18, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleExit, 
                        child: Text("Return", style: TextStyle(fontSize: 18, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}