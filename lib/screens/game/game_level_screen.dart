import 'dart:math' as math; // Import math for rotation
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart';
import '../../services/game_data_manager.dart';
import 'play_game_screen.dart';
import 'game_settings_setup.dart';
import 'word_guess_entry_screen.dart';
// Import your shared bottom panel
import '../../widgets/common_layouts.dart';

class GameLevelScreen extends StatefulWidget {
  const GameLevelScreen({Key? key}) : super(key: key);

  @override
  _GameLevelScreenState createState() => _GameLevelScreenState();
}

class _GameLevelScreenState extends State<GameLevelScreen> {
  final SharedPreferencesHelper _prefs = SharedPreferencesHelper();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _difficulty = "easy";
  int _unlockedLevel = 1;
  Map<int, int> _levelStars = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserGameData();
  }

  Future<void> _loadUserGameData() async {
    User? user = _auth.currentUser;
    
    // Default values
    String loadedDifficulty = "easy";
    int loadedUnlockedLevel = 1;

    if (user != null) {
      try {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          // ⭐ FIX 1: Ensure difficulty is always lowercase to prevent "Hard" vs "hard" bugs
          loadedDifficulty = (data['difficulty'] ?? "easy").toString().toLowerCase();
          loadedUnlockedLevel = data['unlockedLevel'] ?? 1;

          Map<int, int> tempStars = {};
          if (data['levelStars'] != null) {
            Map<String, dynamic> starsMap = data['levelStars'];
            starsMap.forEach((key, value) {
              int lvl = int.parse(key);
              int stars = value as int;
              tempStars[lvl] = stars;
              _prefs.setStarsForLevel(lvl, stars); // Sync local
            });
          }
          if (mounted) {
            setState(() {
              _levelStars = tempStars;
            });
          }
        }
      } catch (e) {
        print("Error fetching data: $e");
      }
    } else {
      // Guest Mode: Load from Prefs
      loadedUnlockedLevel = await _prefs.getUnlockedLevel();
      String? savedDiff = await _prefs.getSavedDifficulty();
      // ⭐ FIX 1: Ensure local prefs are also lowercase
      loadedDifficulty = (savedDiff ?? "easy").toLowerCase();
    }

    // ⭐ SAFETY FIX: If the game was reset (Level 1), force Difficulty to Easy.
    if (loadedUnlockedLevel == 1) {
      loadedDifficulty = "easy";
    }

    if (mounted) {
      setState(() {
        _difficulty = loadedDifficulty;
        _unlockedLevel = loadedUnlockedLevel;
        _loading = false;
      });
    }

    // Sync back to prefs to be safe
    await _prefs.saveDifficulty(loadedDifficulty);
    await _prefs.setUnlockedLevel(loadedUnlockedLevel);
  }

  List<int> _getLevelsForDifficulty() {
    if (_difficulty == 'medium') return [6, 7, 8, 9, 10];
    if (_difficulty == 'hard') return [11, 12, 13, 14, 15];
    // Default to easy if mismatch or 'easy'
    return [1, 2, 3, 4, 5];
  }

  Color _getDifficultyColor() {
    switch (_difficulty) {
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.green;
    }
  }

  void _updateDifficulty(String newDifficulty) async {
    setState(() => _difficulty = newDifficulty);
    _prefs.saveDifficulty(newDifficulty);

    User? user = _auth.currentUser;
    if (user != null) {
      _db.collection('users').doc(user.uid).update({'difficulty': newDifficulty});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<int> levels = _getLevelsForDifficulty();

    return Scaffold(
      // Ensure bottom bar stays put
      bottomNavigationBar: BottomNavPanel(),
      resizeToAvoidBottomInset: false,
      
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFADD8E6), Color(0xFFE0F7FA)],
          ),
        ),
        // ⭐ FIX 2: Switched to CustomScrollView with SliverFillRemaining
        // This solves the responsiveness issue. It allows the content to center vertically
        // when there is space, but scroll naturally on small screens without breaking the layout.
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false, // Ensures content stretches to fill screen
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // ---------- HEADER ----------
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => WordGuessEntryScreen()),
                                );
                              },
                              child: Image.asset('assets/images/back_icon.png', width: 40),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "SELECT LEVEL",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(color: Colors.blue, offset: Offset(2, 2), blurRadius: 4)
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${_difficulty.toUpperCase()} MODE",
                                    style: TextStyle(
                                      color: _getDifficultyColor(),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(color: Colors.white, offset: Offset(0, 1), blurRadius: 1),
                                        Shadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 2),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const GameSettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const Spacer(), // Pushes Grid to Center

                      // ---------- LEVEL GRID ----------
                      Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 500),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLevelButton(levels[0]),
                                  const SizedBox(width: 30),
                                  _buildLevelButton(levels[1]),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLevelButton(levels[2]),
                                  const SizedBox(width: 30),
                                  _buildLevelButton(levels[3]),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLevelButton(levels[4]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(), // Pushes Arrows to Bottom

                      // ---------- DIFFICULTY NAV ----------
                      Container(
                        constraints: BoxConstraints(maxWidth: 500),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNavArrow(
                              Icons.arrow_back,
                              _difficulty == 'easy'
                                  ? null
                                  : () {
                                      if (_difficulty == 'medium') _updateDifficulty('easy');
                                      else if (_difficulty == 'hard') _updateDifficulty('medium');
                                    },
                            ),
                            _buildNavArrow(
                              Icons.arrow_forward,
                              _difficulty == 'hard'
                                  ? null
                                  : () {
                                      if (_difficulty == 'easy') _updateDifficulty('medium');
                                      else if (_difficulty == 'medium') _updateDifficulty('hard');
                                    },
                            ),
                          ],
                        ),
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

  // ---------- LEVEL BUTTON ----------
  Widget _buildLevelButton(int level) {
    bool isLocked = level > _unlockedLevel;
    int starsEarned = _levelStars[level] ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Complete previous levels to unlock!"),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlayGameScreen(level: level)),
          );
        }
      },
      child: Container(
        width: 90, 
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLocked
                ? [Colors.grey.shade400, Colors.grey.shade600]
                : [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2E6DA4), width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(3, 5), blurRadius: 5)
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ⭐ STAR DISPLAY LOGIC
            if (!isLocked)
              if (starsEarned == 3)
                // --- CURVE 3 STAR LAYOUT ---
                Positioned(
                  top: 5, 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform(
                        transform: Matrix4.identity()..translate(0.0, 6.0)..rotateZ(-0.25),
                        alignment: Alignment.center,
                        child: const AnimatedStar(index: 0, earnedStars: 3, size: 18),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.0),
                        child: AnimatedStar(index: 1, earnedStars: 3, size: 24),
                      ),
                      Transform(
                        transform: Matrix4.identity()..translate(0.0, 6.0)..rotateZ(0.25),
                        alignment: Alignment.center,
                        child: const AnimatedStar(index: 2, earnedStars: 3, size: 18),
                      ),
                    ],
                  ),
                )
              else
                // --- STANDARD ROW ---
                Positioned(
                  top: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.0),
                        child: AnimatedStar(
                          index: index, 
                          earnedStars: starsEarned,
                          size: 14, 
                        ),
                      ),
                    ),
                  ),
                ),

            isLocked
                ? const Icon(Icons.lock, color: Colors.white70, size: 35)
                : Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: Text(
                      "$level",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                              color: Colors.black38,
                              offset: Offset(2, 2),
                              blurRadius: 4)
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ---------- ARROWS ----------
  Widget _buildNavArrow(IconData icon, VoidCallback? onTap) {
    bool isDisabled = onTap == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.withOpacity(0.5) : Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            if (!isDisabled)
              BoxShadow(color: Colors.black26, offset: Offset(2, 4), blurRadius: 4)
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}

// -----------------------------------------------------------
//  ANIMATED STAR WIDGET
// -----------------------------------------------------------
class AnimatedStar extends StatefulWidget {
  final int index;
  final int earnedStars;
  final double size; 
  
  const AnimatedStar({
    Key? key, 
    required this.index, 
    required this.earnedStars,
    this.size = 14.0, 
  }) : super(key: key);

  @override
  State<AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<AnimatedStar> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + (widget.index * 200)), 
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut, 
    );

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.index < widget.earnedStars) {
      _scaleController.forward();
      if (widget.earnedStars == 3) {
        _shineController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEarned = widget.index < widget.earnedStars;

    return ScaleTransition(
      scale: isEarned ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
      child: isEarned && widget.earnedStars == 3
          ? _buildShiningStar() 
          : Icon(
              Icons.star,
              color: isEarned ? Colors.amber : Colors.black26,
              size: widget.size,
            ),
    );
  }

  Widget _buildShiningStar() {
    return AnimatedBuilder(
      animation: _shineController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.6 * _shineController.value),
                blurRadius: (widget.size / 2) * _shineController.value,
                spreadRadius: 2 * _shineController.value,
              ),
            ],
          ),
          child: Icon(Icons.star, color: Colors.amber, size: widget.size),
        );
      },
    );
  }
}