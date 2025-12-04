import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Adjust these imports to match your project structure ---
import '../../theme/app_colors.dart'; 
import '../../services/shared_preferences_helper.dart'; 
import 'play_game_screen.dart';
import 'game_settings_setup.dart'; 
import 'word_guess_entry_screen.dart'; 
import '../../widgets/common_layouts.dart'; // Needed for BottomNavPanel

class GameLevelScreen extends StatefulWidget {
  const GameLevelScreen({Key? key}) : super(key: key);

  @override
  _GameLevelScreenState createState() => _GameLevelScreenState();
}

class _GameLevelScreenState extends State<GameLevelScreen> {
  final SharedPreferencesHelper _prefs = SharedPreferencesHelper();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Real-time listener
  StreamSubscription<DocumentSnapshot>? _userStream;

  String _difficulty = "easy";
  int _unlockedLevel = 1;
  bool _isLoading = true;
  
  // This Map holds your stars. Key = Level ID, Value = Number of Stars
  Map<int, int> _levelStars = {}; 

  @override
  void initState() {
    super.initState();
    _loadLocalState();      
    _setupRealtimeSync();   
  }

  @override
  void dispose() {
    _userStream?.cancel(); 
    super.dispose();
  }

  void _loadLocalState() async {
    String savedDiff = await _prefs.getSavedDifficulty();
    int unlocked = await _prefs.getUnlockedLevel();
    
    Map<int, int> loadedStars = {};
    for (int i = 1; i <= 15; i++) {
      int stars = await _prefs.getStarsForLevel(i);
      if (stars > 0) loadedStars[i] = stars;
    }

    if (savedDiff.isEmpty) savedDiff = "easy";
    
    if (mounted) {
      setState(() {
        _difficulty = savedDiff.toLowerCase();
        _unlockedLevel = unlocked;
        _levelStars = loadedStars;
        _isLoading = false;
      });
    }
  }

  // --- REAL-TIME SYNC ---
  void _setupRealtimeSync() {
    User? user = _auth.currentUser;
    if (user != null) {
      _userStream = _db.collection('users').doc(user.uid).snapshots().listen((snapshot) async {
        if (snapshot.exists && mounted) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

          // 1. Sync Unlocked Level
          int cloudUnlocked = data['unlockedLevel'] ?? 1;
          if (cloudUnlocked > _unlockedLevel) {
             _unlockedLevel = cloudUnlocked;
             await _prefs.setUnlockedLevel(cloudUnlocked);
          }

          // 2. Sync Difficulty
          String cloudDiff = data['difficulty'] ?? 'easy';
          if (cloudDiff != _difficulty) {
             _difficulty = cloudDiff;
             await _prefs.saveDifficulty(cloudDiff);
          }

          // 3. Sync Stars (Merging Local + Cloud)
          Map<int, int> mergedStars = Map.from(_levelStars);
          
          if (data.containsKey('levelStars') && data['levelStars'] is Map) {
            Map<dynamic, dynamic> starsMap = data['levelStars'];
            
            starsMap.forEach((key, value) {
              // Robust parsing to handle Strings or Ints from Firestore
              int lvl = int.tryParse(key.toString()) ?? 0;
              int count = int.tryParse(value.toString()) ?? 0;
              
              if (lvl > 0 && count > 0) {
                mergedStars[lvl] = count;
                _prefs.setStarsForLevel(lvl, count); 
              }
            });
          }

          // 4. Update UI
          setState(() {
            _unlockedLevel = cloudUnlocked > _unlockedLevel ? cloudUnlocked : _unlockedLevel;
            _difficulty = cloudDiff;
            _levelStars = mergedStars;
          });
        }
      }, onError: (e) {
        print("Real-time Sync Error: $e");
      });
    }
  }

  void _updateDifficulty(String newDifficulty) async {
    setState(() => _difficulty = newDifficulty);
    await _prefs.saveDifficulty(newDifficulty);

    User? user = _auth.currentUser;
    if (user != null) {
      _db.collection('users').doc(user.uid).update({'difficulty': newDifficulty});
    }
  }

  List<int> _getLevelsForDifficulty() {
    if (_difficulty == 'medium') return [6, 7, 8, 9, 10];
    if (_difficulty == 'hard') return [11, 12, 13, 14, 15];
    return [1, 2, 3, 4, 5]; 
  }

  Color _getDifficultyColor() {
    switch (_difficulty) {
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;    
      default: return Colors.green;  
    }
  }

  @override
  Widget build(BuildContext context) {
    List<int> levels = _getLevelsForDifficulty();

    return Scaffold(
      // Ensure BottomNavPanel is defined in your common_layouts.dart
      bottomNavigationBar: BottomNavPanel(), 
      
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFADD8E6), Color(0xFFE0F7FA)],
          ),
        ),
        child: SafeArea(
          bottom: false, 
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    // --- Header ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WordGuessEntryScreen()));
                            },
                            child: Image.asset('assets/images/back_icon.png', width: 40),
                          ),
                          Column(
                            children: [
                              const Text("SELECT LEVEL", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                              Text("${_difficulty.toUpperCase()} MODE", style: TextStyle(color: _getDifficultyColor(), fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                            onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => const GameSettingsScreen()));
                            },
                          ),
                        ],
                      ),
                    ),

                    // --- Level Grid ---
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [_buildLevelButton(levels[0]), const SizedBox(width: 40), _buildLevelButton(levels[1])],
                              ),
                              const SizedBox(height: 30), 
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [_buildLevelButton(levels[2]), const SizedBox(width: 40), _buildLevelButton(levels[3])],
                              ),
                              const SizedBox(height: 30), 
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [_buildLevelButton(levels[4])],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- Arrows ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNavArrow(Icons.arrow_back, _difficulty == 'easy' ? null : () {
                              if (_difficulty == 'medium') _updateDifficulty('easy');
                              else if (_difficulty == 'hard') _updateDifficulty('medium');
                          }),
                          _buildNavArrow(Icons.arrow_forward, _difficulty == 'hard' ? null : () {
                              if (_difficulty == 'easy') _updateDifficulty('medium');
                              else if (_difficulty == 'medium') _updateDifficulty('hard');
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // --- THIS WIDGET HANDLES THE STAR DISPLAY ---
  Widget _buildLevelButton(int level) {
    bool isLocked = level > _unlockedLevel;
    int starCount = _levelStars[level] ?? 0;
    
    // Check if we have stars to show
    bool hasStars = !isLocked && starCount > 0;
    
    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Level is locked"), duration: Duration(seconds: 1), backgroundColor: Colors.redAccent));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PlayGameScreen(level: level)));
        }
      },
      child: Container(
        width: 100, height: 100, 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLocked ? [Colors.grey.shade400, Colors.grey.shade600] : [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: const Color(0xFF2E6DA4), width: 4),
          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(4, 6), blurRadius: 6)],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Stars positioned at the top
            if (hasStars)
              Positioned(
                top: 5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Icon(
                      index < starCount ? Icons.star : Icons.star_border, 
                      color: index < starCount ? Colors.amber : Colors.white30, 
                      size: 22, 
                    );
                  }),
                ),
              ),
            
            // Level Number or Lock Icon
            isLocked
                ? const Icon(Icons.lock, color: Colors.white70, size: 40)
                : Padding(
                    // Moves the text down if stars are present
                    padding: EdgeInsets.only(top: hasStars ? 22.0 : 0.0), 
                    child: Text("$level", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey : Colors.red,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(2, 4), blurRadius: 4)],
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}