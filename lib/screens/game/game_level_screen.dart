import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart';
import '../../services/game_data_manager.dart';
import 'play_game_screen.dart';
import 'game_settings_setup.dart';
import 'word_guess_entry_screen.dart';
import '../home_screen.dart';

// ⭐ NEW IMPORT for shared bottom panel
import '../../widgets/common_layouts.dart';

class GameLevelScreen extends StatefulWidget {
  const GameLevelScreen({Key? key}) : super(key: key);

  @override
  _GameLevelScreenState createState() => _GameLevelScreenState();
}

class _GameLevelScreenState extends State<GameLevelScreen> {
  final SharedPreferencesHelper _prefs = SharedPreferencesHelper();
  final GameDataManager _gameDataManager = GameDataManager();
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

    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _difficulty = data['difficulty'] ?? "easy";
          _unlockedLevel = data['unlockedLevel'] ?? 1;

          _levelStars = {};
          if (data['levelStars'] != null) {
            Map<String, dynamic> starsMap = data['levelStars'];
            starsMap.forEach((key, value) {
              int lvl = int.parse(key);
              int stars = value as int;
              _levelStars[lvl] = stars;
              _prefs.setStarsForLevel(lvl, stars);
            });
          }
        });
      }
    }

    _prefs.saveDifficulty(_difficulty);
    _prefs.setUnlockedLevel(_unlockedLevel);

    setState(() => _loading = false);
  }

  List<int> _getLevelsForDifficulty() {
    if (_difficulty == 'medium') return [6, 7, 8, 9, 10];
    if (_difficulty == 'hard') return [11, 12, 13, 14, 15];
    return [1, 2, 3, 4, 5];
  }

  Color _getDifficultyColor() {
    switch (_difficulty) {
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.green;
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<int> levels = _getLevelsForDifficulty();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFADD8E6), Color(0xFFE0F7FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ---------- HEADER ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => WordGuessEntryScreen()),
                        );
                      },
                      child: Image.asset('assets/images/back_icon.png', width: 40),
                    ),
                    Column(
                      children: [
                        const Text(
                          "SELECT LEVEL",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  color: Colors.blue,
                                  offset: Offset(2, 2),
                                  blurRadius: 4)
                            ],
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

              // ---------- LEVEL GRID ----------
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLevelButton(levels[0]),
                            const SizedBox(width: 40),
                            _buildLevelButton(levels[1]),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLevelButton(levels[2]),
                            const SizedBox(width: 40),
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
              ),

              // ---------- DIFFICULTY NAV ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavArrow(
                      Icons.arrow_back,
                      _difficulty == 'easy'
                          ? null
                          : () {
                              if (_difficulty == 'medium') {
                                _updateDifficulty('easy');
                              } else if (_difficulty == 'hard') {
                                _updateDifficulty('medium');
                              }
                            },
                    ),
                    _buildNavArrow(
                      Icons.arrow_forward,
                      _difficulty == 'hard'
                          ? null
                          : () {
                              if (_difficulty == 'easy') {
                                _updateDifficulty('medium');
                              } else if (_difficulty == 'medium') {
                                _updateDifficulty('hard');
                              }
                            },
                    ),
                  ],
                ),
              ),

              // ⭐ USE SHARED BOTTOM PANEL
              BottomNavPanel(),
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
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Level is locked"),
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
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLocked
                ? [Colors.grey.shade400, Colors.grey.shade600]
                : [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2E6DA4), width: 4),
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(4, 6), blurRadius: 6)
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!isLocked)
              Positioned(
                top: 8,
                child: Row(
                  children: List.generate(
                    3,
                    (index) => Icon(
                      Icons.star,
                      color: index < starsEarned ? Colors.amber : Colors.black26,
                      size: 16,
                    ),
                  ),
                ),
              ),
            isLocked
                ? const Icon(Icons.lock, color: Colors.white70, size: 40)
                : Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      "$level",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey : Colors.red,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(2, 4), blurRadius: 4)
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}
