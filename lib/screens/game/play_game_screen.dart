import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart';
import 'game_level_screen.dart';
import 'game_over_screen.dart';
import 'game_settings_setup.dart'; 

class PlayGameScreen extends StatefulWidget {
  final int level;
  const PlayGameScreen({Key? key, required this.level}) : super(key: key);

  @override
  _PlayGameScreenState createState() => _PlayGameScreenState();
}

class _PlayGameScreenState extends State<PlayGameScreen> with WidgetsBindingObserver {
  // --- Audio ---
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // --- Firebase & Prefs ---
  final SharedPreferencesHelper _prefs = SharedPreferencesHelper();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Game State ---
  late int _currentLevel;
  String _targetWord = "";
  List<String> _selectedLetters = [];
  bool _isGameFinished = false;
  bool _isSuccess = false;
  bool _showHint = false;
  String _hintText = "";

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
    
    _currentLevel = widget.level;
    _initializeLevel();
    _updateSettingsAndAudio(startMusic: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _bgmPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isGameFinished || !_isSuccess) {
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
    _showHint = false;
    _hintText = "";

    _prefs.setCurrentLevel(_currentLevel);
  }

  // --- Settings & Audio Methods ---
  
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
      if (_bgmPlayer.state != PlayerState.playing && (!_isGameFinished || !_isSuccess)) {
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

  // UPDATED: Using heavyImpact for stronger vibration
  void _triggerVibration() {
    if (_vibrationEnabled) {
      HapticFeedback.heavyImpact(); 
    }
  }

  // --- Helper: Get Image Asset ---
  String _getLevelImage(int level) {
    switch(level) {
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

  // --- Logic: Hint ---
  void _toggleHint() {
    _triggerVibration(); // Added vibration on toggle
    setState(() {
      if (_showHint) {
        _showHint = false;
      } else {
        _hintText = _generateHint(_targetWord);
        _showHint = true;
      }
    });
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
    for(int i=0; i<answerChars.length; i++) {
        if(answerChars[i] != ' ') validIndices.add(i);
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

  // --- Interaction ---
  void _onKeyPress(String char) {
    if (_isGameFinished && _isSuccess) return; 
    
    _triggerVibration(); // Vibration on key press
    setState(() {
      if (_isGameFinished && !_isSuccess) {
        _isGameFinished = false;
        _isSuccess = false;
      }
      _selectedLetters.add(char);
    });
    _playSound('pop');
  }

  // --- BACKSPACE LOGIC ---
  
  // Single Tap: Deletes one character
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

  // Long Press: Clears ALL characters
  void _onClearAll() {
    if (_isGameFinished && _isSuccess) return;

    _triggerVibration();
    if (_selectedLetters.isNotEmpty) {
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
    _triggerVibration(); // Vibration on Submit/Next Level

    if (_isGameFinished && _isSuccess) {
      if (_isFinalLevel()) {
        _redirectToGameOver();
      } else {
        _goToNextLevel();
      }
      return;
    }

    String userAnswer = _selectedLetters.join("").trim().toUpperCase();
    String correctAnswer = _targetWord.trim().toUpperCase();

    if (userAnswer == correctAnswer) {
      _playSound('correct');
      _handleCorrectAnswer();
    } else {
      _playSound('wrong');
      setState(() {
        _isGameFinished = true; // Shows "Incorrect"
        _isSuccess = false;    
      });
    }
  }

  void _handleCorrectAnswer() async {
    setState(() {
      _isGameFinished = true;
      _isSuccess = true;
    });

    int unlockedLevel = await _prefs.getUnlockedLevel();
    if (_currentLevel >= unlockedLevel) {
      await _prefs.setUnlockedLevel(_currentLevel + 1);

      User? user = _auth.currentUser;
      if (user != null) {
        _db.collection('users').doc(user.uid).update({
          'unlockedLevel': _currentLevel + 1
        });
      }
    }
  }

  bool _isFinalLevel() {
    return (_currentLevel == 5 || _currentLevel == 10 || _currentLevel == 15);
  }

  void _redirectToGameOver() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameOverScreen(level: _currentLevel)),
    );
  }

  void _goToNextLevel() async {
    int nextLevel = _currentLevel + 1;
    if (nextLevel > _correctAnswers.length) nextLevel = 1;

    await _prefs.setCurrentLevel(nextLevel);

    User? user = _auth.currentUser;
    if (user != null) {
      _db.collection('users').doc(user.uid).update({
        'currentLevel': nextLevel
      });
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PlayGameScreen(level: nextLevel)),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameSettingsScreen(
          // Immediate BGM update
          onBgmVolumeChanged: (vol) {
            _bgmVolume = vol;
            _bgmPlayer.setVolume(vol);
          },
          // Immediate SFX update
          onSfxVolumeChanged: (vol) {
            _sfxVolume = vol;
            _sfxPlayer.setVolume(vol);
          },
          // Immediate Vibration update
          onVibrationChanged: (val) {
            _vibrationEnabled = val;
            _triggerVibration(); // Test vibrate when toggled
          },
        ),
      ),
    ).then((_) {
      _updateSettingsAndAudio(startMusic: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = "Submit";
    if (_isGameFinished) {
      if (_isSuccess) {
        buttonText = _isFinalLevel() ? "Finish Game" : "Next Level";
      } else {
        buttonText = "Submit"; 
      }
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // --- Top Bar ---
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameLevelScreen()));
                      },
                      child: Image.asset('assets/images/back_icon.png', width: 40)
                    ),
                    Spacer(),
                    Column(
                      children: [
                        Text("Level $_currentLevel", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          _currentLevel <= 5 ? "Easy" : (_currentLevel <= 10 ? "Medium" : "Hard"),
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                      onPressed: _openSettings,
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // --- Level Image ---
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.secondary, width: 3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.asset(
                            _getLevelImage(_currentLevel),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),

                      // --- Word Display ---
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _selectedLetters.isEmpty ? "..." : _selectedLetters.join(""),
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                        ),
                      ),
                      
                      SizedBox(height: 10),

                      // --- Result / Hint Section ---
                      if (_isGameFinished) ...[
                        if (_isSuccess)
                          Column(
                            children: [
                              Image.asset('assets/images/correct.png', height: 40),
                              Text("Correct! Well done.", style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Image.asset('assets/images/wrong.png', height: 40),
                              Text("Incorrect! Try again.", style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          )
                      ] else ...[
                          if (_showHint) ...[
                            // Hint Text
                            Container(
                              padding: EdgeInsets.all(12),
                              margin: EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.black26, 
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber, width: 2)
                              ),
                              child: Text(
                               _hintText, 
                               style: TextStyle(fontSize: 24, letterSpacing: 2, color: Colors.amberAccent, fontWeight: FontWeight.bold)
                              ),
                            ),
                            
                            // Close Hint Button
                            ElevatedButton.icon(
                              onPressed: _toggleHint,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent, 
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: StadiumBorder(),
                                elevation: 4,
                              ),
                              icon: Icon(Icons.close, color: Colors.white, size: 24),
                              label: Text(
                                "Close Hint", 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ] else ...[
                            // Show Hint Button
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _toggleHint,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: StadiumBorder(),
                                elevation: 5,
                              ),
                              icon: Icon(Icons.lightbulb, size: 22, color: Colors.yellowAccent),
                              label: Text(
                                "Need a Hint?", 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                      ],

                      SizedBox(height: 20),

                      // --- Alphabet Grid ---
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                        ),
                        itemCount: _alphabet.length + 1, 
                        itemBuilder: (ctx, i) {
                          if (i == _alphabet.length) {
                            return _buildKeyBtn("SPC");
                          }
                          return _buildKeyBtn(_alphabet[i]);
                        },
                      ),

                      SizedBox(height: 20),

                      // --- Bottom Controls ---
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _triggerVibration(); // ADDED VIBRATION TO RETRY
                                if (_isGameFinished && !_isSuccess) {
                                  // Retry (Clear All)
                                  setState(() {
                                    _isGameFinished = false;
                                    _selectedLetters.clear();
                                  });
                                } else {
                                  _handleSubmit();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                (_isGameFinished && !_isSuccess) ? "Retry" : buttonText, 
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          
                          // --- UPDATED BACKSPACE BUTTON ---
                          GestureDetector(
                            onTap: _onBackspace,     // Tap to delete one
                            onLongPress: _onClearAll, // Long press to delete all
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.backspace, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
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
          boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0,2), blurRadius: 2)],
        ),
        alignment: Alignment.center,
        child: Text(
          char, 
          style: TextStyle(
            fontSize: char == "SPC" ? 14 : 20, 
            fontWeight: FontWeight.bold, 
            color: AppColors.primary
          )
        ),
      ),
    );
  }
}