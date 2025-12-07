import 'dart:io'; // For Platform checking
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ensure these paths match your project structure
import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart';
import '../../services/game_data_manager.dart';
import 'game_level_screen.dart';
import 'game_over_screen.dart';
import 'game_settings_setup.dart';

class PlayGameScreen extends StatefulWidget {
  final int level;
  const PlayGameScreen({Key? key, required this.level}) : super(key: key);

  @override
  _PlayGameScreenState createState() => _PlayGameScreenState();
}

class _PlayGameScreenState extends State<PlayGameScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // --- Audio ---
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _shouldResumeMusic = false;

  // --- Animation ---
  late AnimationController _bulbController;
  late Animation<double> _bulbAnimation;

  // --- Star Animation Controller ---
  late AnimationController _starController;
  late Animation<double> _starScaleAnimation;

  // --- Firebase & Prefs ---
  final SharedPreferencesHelper _prefs = SharedPreferencesHelper();
  final GameDataManager _dataManager = GameDataManager();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Game State ---
  late int _currentLevel;
  String _targetWord = "";
  List<String> _selectedLetters = [];
  bool _isGameFinished = false; // Used to lock input
  bool _isSuccess = false;
  
  // Hint State
  String _hintText = "";
  int _hintUsageCounter = 0;

  // Track stars earned in this session
  int _currentRunStars = 0;

  // --- Settings State ---
  double _bgmVolume = 0.5;
  double _sfxVolume = 1.0;
  bool _vibrationEnabled = true;

  // --- Data ---
  final List<String> _correctAnswers = [
    "BABU", "SIYOK", "RABIT", "GAON", "TUKIN",
    "NDUNG", "JIPUH", "SIRUH", "BUSING", "KESONG",
    "SIEN", "PANU KAJAK", "KERETA BIRU", "PIIN KOSONG", "TUBIK"
  ];
  final String _alphabet = "ABDEGHIJKNOPRSTUY";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // --- Audio Context ---
    AudioPlayer.global.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));

    // --- Animation for Shining Bulb ---
    _bulbController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // Pulse back and forth

    _bulbAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _bulbController, curve: Curves.easeInOut),
    );

    // --- Animation for Shining Star (Winner) ---
    _starController = AnimationController(
      duration: const Duration(milliseconds: 700), // Slightly faster pulse
      vsync: this,
    );
    
    // Create a pulsing effect (scale up and down)
    _starScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeInOut),
    );

    _currentLevel = widget.level;
    _initializeLevel();
    _updateSettingsAndAudio(startMusic: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_bgmPlayer.state == PlayerState.playing) {
        _shouldResumeMusic = true;
        _bgmPlayer.pause();
      }
    }
    if (state == AppLifecycleState.resumed) {
      if (_shouldResumeMusic) {
        _shouldResumeMusic = false;
        _bgmPlayer.resume();
      }
    }
  }

  void _initializeLevel() {
    if (_currentLevel < 1) _currentLevel = 1;
    if (_currentLevel > _correctAnswers.length) _currentLevel = 1;

    _targetWord = _correctAnswers[_currentLevel - 1];
    _selectedLetters.clear();
    _isGameFinished = false;
    _isSuccess = false;
    
    _hintText = "";
    _hintUsageCounter = 0;
    _currentRunStars = 0;

    _prefs.setCurrentLevel(_currentLevel);
  }

  Future<void> _updateSettingsAndAudio({bool startMusic = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    if (mounted) {
      setState(() {
        _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.5;
        _sfxVolume = prefs.getDouble('sfx_volume') ?? 1.0;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      });
    }

    await _bgmPlayer.setVolume(_bgmVolume);
    await _sfxPlayer.setVolume(_sfxVolume);

    if (startMusic) {
      _playRandomBackgroundMusic();
    } else {
      if (_bgmPlayer.state != PlayerState.playing && !_isGameFinished) {
        _bgmPlayer.resume();
      }
    }
  }

  void _playRandomBackgroundMusic() async {
    if (_bgmPlayer.state == PlayerState.playing) {
      await _bgmPlayer.setVolume(_bgmVolume);
      return;
    }
    int index = Random().nextInt(10) + 1;
    String musicFile = 'audio/pou$index.mp3';
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(_bgmVolume);
    await _bgmPlayer.play(AssetSource(musicFile));
  }

  void _playSound(String name) {
    _sfxPlayer.setVolume(_sfxVolume);
    _sfxPlayer.stop().then((_) {
      _sfxPlayer.play(AssetSource('audio/$name.mp3'));
    });
  }

  // --- VIBRATION LOGIC ---
  void _triggerVibration() {
    if (_vibrationEnabled) {
      if (Platform.isAndroid) {
        HapticFeedback.vibrate(); 
      } else {
        HapticFeedback.mediumImpact(); 
      }
    }
  }

  String _getLevelImage(int level) {
    switch (level) {
      case 1: return 'assets/images/babu.png';
      case 2: return 'assets/images/siyok.png';
      case 3: return 'assets/images/rabit.png';
      case 4: return 'assets/images/gaon.png';
      case 5: return 'assets/images/tukin.png';
      case 6: return 'assets/images/ndung.png';
      case 7: return 'assets/images/jipuh.png';
      case 8: return 'assets/images/siruh.png';
      case 9: return 'assets/images/busing.png';
      case 10: return 'assets/images/kesong.png';
      case 11: return 'assets/images/sien.png';
      case 12: return 'assets/images/panu_kajak.png';
      case 13: return 'assets/images/kereta_biru.png';
      case 14: return 'assets/images/piin_kosong.png';
      case 15: return 'assets/images/tubik.png';
      default: return 'assets/images/babu.png';
    }
  }

  // --- Hint Logic ---
  void _triggerHintPopup() {
    _triggerVibration();
    setState(() {
      _hintText = _generateHint(_targetWord);
      _hintUsageCounter++;
    });
    _showHintDialog();
  }

  String _generateHint(String answer) {
    List<String> answerChars = answer.split('');
    List<String> hintChars = [];

    for (var char in answerChars) {
      if (char == ' ') {
        hintChars.add("   ");
      } else {
        hintChars.add("_");
      }
    }

    Random rand = Random();
    int revealedCount = 0;
    List<int> validIndices = [];
    
    for (int i = 0; i < answerChars.length; i++) {
      if (answerChars[i] != ' ') validIndices.add(i);
    }

    while (revealedCount < 2 && validIndices.isNotEmpty) {
      int randomIndex = rand.nextInt(validIndices.length);
      int actualIndex = validIndices[randomIndex];
      
      if (hintChars[actualIndex] == "_") {
        hintChars[actualIndex] = answerChars[actualIndex];
        revealedCount++;
        validIndices.removeAt(randomIndex);
      }
    }
    return hintChars.join(" ");
  }

  // --- Input ---
  void _onKeyPress(String char) {
    if (_isGameFinished && _isSuccess) return;
    _triggerVibration(); 
    setState(() {
      if (_isGameFinished && !_isSuccess) {
        _isGameFinished = false;
        _isSuccess = false;
      }
      _selectedLetters.add(char);
    });
    _playSound('pop');
  }

  void _onBackspace() {
    if (_isGameFinished && _isSuccess) return;
    _triggerVibration();
    if (_selectedLetters.isNotEmpty) {
      setState(() {
        _selectedLetters.removeLast();
        if (_isGameFinished && !_isSuccess) {
          _isGameFinished = false;
          _isSuccess = false;
        }
      });
      _playSound('backspace');
    }
  }

  void _onClearAll() {
    if (_isGameFinished && _isSuccess) return;
    if (_selectedLetters.isNotEmpty) {
      _triggerVibration();
      setState(() {
        _selectedLetters.clear();
        if (_isGameFinished && !_isSuccess) {
          _isGameFinished = false;
          _isSuccess = false;
        }
      });
      _playSound('backspace');
    }
  }

  void _handleSubmit() {
    _triggerVibration();
    
    String userAnswer = _selectedLetters.join("").trim().toUpperCase();
    String correctAnswer = _targetWord.trim().toUpperCase();

    if (userAnswer == correctAnswer) {
      _playSound('correct');
      _handleCorrectAnswer();
    } else {
      _playSound('wrong');
      _showWrongDialog();
    }
  }

  void _handleCorrectAnswer() async {
    int starsEarned;
    if (_hintUsageCounter <= 3) {
      starsEarned = 3;
    } else if (_hintUsageCounter <= 6) {
      starsEarned = 2;
    } else {
      starsEarned = 1;
    }

    int currentBestStars = await _prefs.getStarsForLevel(_currentLevel);

    setState(() {
      _isGameFinished = true;
      _isSuccess = true;
      _currentRunStars = starsEarned;
    });

    if (starsEarned > currentBestStars) {
      await _prefs.setStarsForLevel(_currentLevel, starsEarned);
      await _dataManager.saveLevelStars(_currentLevel, starsEarned);
    }

    User? user = _auth.currentUser;
    int serverUnlockedLevel = 1;

    if (user != null) {
      try {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
           serverUnlockedLevel = doc.get('unlockedLevel') ?? 1;
        }
      } catch (e) {
        serverUnlockedLevel = await _prefs.getUnlockedLevel();
      }

      if (_currentLevel >= serverUnlockedLevel) {
        await _db.collection('users').doc(user.uid).update({
          'unlockedLevel': _currentLevel + 1,
        });
        await _prefs.setUnlockedLevel(_currentLevel + 1);
      }
    } else {
      int localUnlocked = await _prefs.getUnlockedLevel();
      if (_currentLevel >= localUnlocked) {
        await _prefs.setUnlockedLevel(_currentLevel + 1);
      }
    }

    _showCorrectDialog(starsEarned);
  }

  bool _isFinalLevel() {
    return (_currentLevel == 5 || _currentLevel == 10 || _currentLevel == 15);
  }

  // --- DIALOGS ---

  void _showStarRulesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.amber[700], size: 32),
                    SizedBox(width: 12),
                    Text(
                      "Scoring Rules",
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  "Use hints wisely to earn maximum stars!\nEach time you generate a hint, it counts as usage.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15, 
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildRuleRow(3, "0 - 3 Hints used"),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Colors.grey[300]),
                      ),
                      _buildRuleRow(2, "4 - 6 Hints used"),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Colors.grey[300]),
                      ),
                      _buildRuleRow(1, "7+ Hints used"),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                        _triggerVibration(); 
                        Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(
                      "Got it!", 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      )
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuleRow(int stars, String text) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => Icon(
            Icons.star_rounded, 
            size: 24, 
            color: index < stars ? Colors.amber : Colors.grey[300]
          )),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              color: Colors.black87
            )
          ),
        ),
      ],
    );
  }

  void _showHintDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.blueGrey[900],
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lightbulb, color: Colors.yellowAccent, size: 40),
                    SizedBox(width: 10),
                    Text(
                      "Hint",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber, width: 2)
                  ),
                  child: Text(
                    _hintText,
                    style: TextStyle(
                      fontSize: 30,
                      letterSpacing: 4,
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: () {
                    _triggerVibration(); 
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  icon: Icon(Icons.close, color: Colors.white),
                  label: Text("Close Hint", style: TextStyle(color: Colors.white, fontSize: 18)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWrongDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/wrong.png', height: 60),
                SizedBox(height: 15),
                Text(
                  "Incorrect!",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Try again",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    _triggerVibration(); 
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: Text("Retry", style: TextStyle(color: Colors.white, fontSize: 18)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCorrectDialog(int stars) {
    // START the star animation immediately when dialog shows
    if (stars == 3) {
      _starController.repeat(reverse: true);
    } else {
      _starController.reset();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 20, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // REPLACED: New Star Display Logic
                    _buildStarDisplay(stars),
                    
                    SizedBox(height: 15),
                    Text(
                      "Correct! Well done.",
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    Image.asset('assets/images/correct.png', height: 50),
                    SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () {
                        _triggerVibration(); 
                        // Stop animation when leaving
                        _starController.stop(); 
                        Navigator.of(ctx).pop();
                        if (_isFinalLevel()) {
                          _redirectToGameOver();
                        } else {
                          _goToNextLevel();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        elevation: 5,
                      ),
                      child: Text(
                        _isFinalLevel() ? "Finish Game" : "Next Level",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- STAR DISPLAY LOGIC ---
  Widget _buildStarDisplay(int stars) {
    if (stars == 3) {
      // 3-Star Curve with FULL ANIMATION
      return SizedBox(
        height: 100, 
        width: 180, 
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Left Star (Tilted Left, Scaled, Glowing)
            Positioned(
              left: 0,
              bottom: 0,
              child: ScaleTransition(
                scale: _starScaleAnimation,
                child: Transform.rotate(
                  angle: -20 * pi / 180, // -20 degrees
                  child: _buildGlowingStar(50),
                ),
              ),
            ),
            // Right Star (Tilted Right, Scaled, Glowing)
            Positioned(
              right: 0,
              bottom: 0,
              child: ScaleTransition(
                scale: _starScaleAnimation,
                child: Transform.rotate(
                  angle: 20 * pi / 180, // 20 degrees
                  child: _buildGlowingStar(50),
                ),
              ),
            ),
            // Center Star (Higher, Scaled, Glowing)
            Positioned(
              top: 0,
              child: ScaleTransition(
                scale: _starScaleAnimation, 
                child: _buildGlowingStar(70),
              ),
            ),
          ],
        ),
      );
    } else {
      // For 1 or 2 Stars (Static)
      return Row(
        mainAxisSize: MainAxisSize.min, 
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          bool isEarned = index < stars;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0), 
            child: Icon(
              Icons.star_rounded,
              color: isEarned ? Colors.amber : Colors.grey[300],
              size: 45, 
            ),
          );
        }),
      );
    }
  }

  // Helper widget to add glow/shine to stars
  Widget _buildGlowingStar(double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.6), // Shine effect
            blurRadius: 15,
            spreadRadius: 2,
          )
        ]
      ),
      child: Icon(Icons.star_rounded, color: Colors.amber, size: size),
    );
  }

  // --- Navigation ---
  void _redirectToGameOver() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverScreen(level: _currentLevel),
      ),
    );
  }

  void _goToNextLevel() async {
    int nextLevel = _currentLevel + 1;
    if (nextLevel > _correctAnswers.length) nextLevel = 1;

    await _prefs.setCurrentLevel(nextLevel);

    User? user = _auth.currentUser;
    if (user != null) {
      _db.collection('users').doc(user.uid).update({
        'currentLevel': nextLevel,
      });
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PlayGameScreen(level: nextLevel)),
    );
  }

  void _openSettings() async {
    _triggerVibration(); 
    await _bgmPlayer.pause();
    _shouldResumeMusic = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameSettingsScreen(
          onBgmVolumeChanged: (vol) {
            _bgmVolume = vol;
            _bgmPlayer.setVolume(vol);
          },
          onSfxVolumeChanged: (vol) {
            _sfxVolume = vol;
            _sfxPlayer.setVolume(vol);
          },
          onVibrationChanged: (val) {
            _vibrationEnabled = val;
            _triggerVibration();
          },
        ),
      ),
    ).then((_) {
      if (_shouldResumeMusic) {
        _shouldResumeMusic = false;
        _bgmPlayer.resume();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bulbController.dispose(); 
    _starController.dispose(); 
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // --- FIXED TOP HEADER ---
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _triggerVibration(); 
                      _shouldResumeMusic = false;
                      _bgmPlayer.stop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameLevelScreen(),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/back_icon.png',
                      width: 40,
                    ),
                  ),
                  Spacer(),
                  Column(
                    children: [
                      Text(
                        "Level $_currentLevel",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currentLevel <= 5
                            ? "Easy"
                            : (_currentLevel <= 10 ? "Medium" : "Hard"),
                        style:
                            TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings,
                        color: Colors.white, size: 30),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),

            // --- SCROLLABLE GAME AREA ---
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 600),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 10),
                              
                              // 1. IMAGE CONTAINER
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.secondary, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26, 
                                      blurRadius: 4, 
                                      offset: Offset(0, 4)
                                    )
                                  ]
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.asset(
                                    _getLevelImage(_currentLevel),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              SizedBox(height: 20),

                              // 2. WORD DISPLAY
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white30, width: 1)
                                ),
                                child: Center(
                                  child: Text(
                                    _selectedLetters.isEmpty
                                        ? "Answer in Bidayuh Word"
                                        : _selectedLetters.join(""),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 20),

                              // 3. SHINING HINT BUTTON + HELP ICON
                              if (!_isGameFinished)
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Hint Button
                                      ElevatedButton.icon(
                                        onPressed: _triggerHintPopup,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber.shade700,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                          shape: StadiumBorder(),
                                          elevation: 5,
                                        ),
                                        icon: ScaleTransition(
                                          scale: _bulbAnimation,
                                          child: Icon(Icons.lightbulb,
                                              size: 32, 
                                              color: Colors.yellowAccent),
                                        ),
                                        label: Text(
                                          "Need a Hint?",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      
                                      SizedBox(width: 12),
                                      
                                      // Help Icon Button
                                      InkWell(
                                        onTap: _showStarRulesDialog,
                                        borderRadius: BorderRadius.circular(30),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white54, width: 2)
                                          ),
                                          child: Icon(
                                            Icons.help_outline,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(height: 15),

                              // 4. KEYBOARD GRID
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _alphabet.length + 1,
                                itemBuilder: (ctx, i) {
                                  if (i == _alphabet.length) {
                                    return _buildKeyBtn("SPC");
                                  }
                                  return _buildKeyBtn(_alphabet[i]);
                                },
                              ),

                              SizedBox(height: 25),

                              // 5. CONTROL BUTTONS
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_isGameFinished && _isSuccess) return;
                                        _handleSubmit();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        "Submit",
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: _onBackspace,
                                    onLongPress: _onClearAll,
                                    child: Container(
                                      padding: EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black26, offset: Offset(0,2), blurRadius: 2)
                                        ]
                                      ),
                                      child: Icon(
                                        Icons.backspace,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyBtn(String char) {
    return GestureDetector(
      onTap: () => _onKeyPress(char == "SPC" ? " " : char),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 3),
                blurRadius: 2)
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          char,
          style: TextStyle(
            fontSize: char == "SPC" ? 14 : 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}