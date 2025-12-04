import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    with WidgetsBindingObserver {
  // --- Audio ---
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _shouldResumeMusic = false; 

  // --- Firebase & Prefs ---
  final SharedPreferencesHelper _prefs = SharedPreferencesHelper();
  final GameDataManager _dataManager = GameDataManager();
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
  int _hintUsageCounter = 0; 
  
  // ⭐ NEW: Track stars earned in this session for display
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
    _showHint = false;
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
      if (_bgmPlayer.state != PlayerState.playing &&
          (!_isGameFinished || !_isSuccess)) {
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

  void _triggerVibration() {
    if (_vibrationEnabled) {
      HapticFeedback.heavyImpact();
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

  // --- Hint ---
  void _toggleHint() {
    _triggerVibration();
    setState(() {
      if (_showHint) {
        _showHint = false;
      } else {
        _hintText = _generateHint(_targetWord);
        _showHint = true;
        _hintUsageCounter++;
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
      HapticFeedback.vibrate();
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
        _isGameFinished = true;
        _isSuccess = false;
      });
    }
  }

  void _handleCorrectAnswer() async {
    // 1. Calculate Stars for THIS run
    int starsEarned;
    if (_hintUsageCounter <= 3) {
      starsEarned = 3;
    } else if (_hintUsageCounter <= 6) {
      starsEarned = 2;
    } else {
      starsEarned = 1;
    }

    // 2. Fetch current BEST score from storage
    // (This ensures we don't overwrite a 3-star score with a 1-star score)
    int currentBestStars = await _prefs.getStarsForLevel(_currentLevel);

    setState(() {
      _isGameFinished = true;
      _isSuccess = true;
      _currentRunStars = starsEarned; // Store for display
    });

    // 3. Only save if new score is BETTER
    if (starsEarned > currentBestStars) {
      await _prefs.setStarsForLevel(_currentLevel, starsEarned);
      await _dataManager.saveLevelStars(_currentLevel, starsEarned);
    }

    // 4. Robust Unlock Sync
    User? user = _auth.currentUser;
    int serverUnlockedLevel = 1;

    if (user != null) {
      try {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
           serverUnlockedLevel = doc.get('unlockedLevel') ?? 1;
        }
      } catch (e) {
        print("Error fetching server unlocked level: $e");
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
  }

  bool _isFinalLevel() {
    return (_currentLevel == 5 || _currentLevel == 10 || _currentLevel == 15);
  }

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
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currentLevel <= 5
                            ? "Easy"
                            : (_currentLevel <= 10 ? "Medium" : "Hard"),
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12),
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

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.secondary,
                              width: 3),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(13),
                          child: Image.asset(
                            _getLevelImage(_currentLevel),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          _selectedLetters.isEmpty
                              ? "..."
                              : _selectedLetters.join(""),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      SizedBox(height: 10),

                      // ⭐ UPDATE: Result Logic
                      if (_isGameFinished) ...[
                        if (_isSuccess)
                          Column(
                            children: [
                              Image.asset(
                                  'assets/images/correct.png',
                                  height: 40),
                              Text(
                                "Correct! Well done.",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              // ⭐ Display Stars Earned Visual
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  // e.g. if _currentRunStars is 2: 
                                  // Index 0: < 2 (True) -> Gold
                                  // Index 1: < 2 (True) -> Gold
                                  // Index 2: < 2 (False) -> Grey
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Icon(
                                      Icons.star,
                                      color: index < _currentRunStars 
                                          ? Colors.amber 
                                          : Colors.white24,
                                      size: 32,
                                      shadows: [
                                        Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(2,2))
                                      ],
                                    ),
                                  );
                                }),
                              )
                            ],
                          )
                        else
                          Column(
                            children: [
                              Image.asset(
                                  'assets/images/wrong.png',
                                  height: 40),
                              Text(
                                "Incorrect! Try again.",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                      ] else ...[
                        if (_showHint) ...[
                          Container(
                            padding: EdgeInsets.all(12),
                            margin:
                                EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.amber,
                                  width: 2),
                            ),
                            child: Text(
                              _hintText,
                              style: TextStyle(
                                fontSize: 24,
                                letterSpacing: 2,
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _toggleHint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.redAccent,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12),
                              shape: StadiumBorder(),
                              elevation: 4,
                            ),
                            icon: Icon(Icons.close,
                                color: Colors.white,
                                size: 24),
                            label: Text(
                              "Close Hint",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _toggleHint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.amber.shade700,
                              foregroundColor:
                                  Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12),
                              shape: StadiumBorder(),
                              elevation: 5,
                            ),
                            icon: Icon(Icons.lightbulb,
                                size: 22,
                                color: Colors
                                    .yellowAccent),
                            label: Text(
                              "Need a Hint?",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],

                      SizedBox(height: 20),

                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                            NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                        ),
                        itemCount:
                            _alphabet.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == _alphabet.length) {
                            return _buildKeyBtn("SPC");
                          }
                          return _buildKeyBtn(
                              _alphabet[i]);
                        },
                      ),

                      SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _triggerVibration();
                                if (_isGameFinished &&
                                    !_isSuccess) {
                                  setState(() {
                                    _isGameFinished =
                                        false;
                                    _selectedLetters
                                        .clear();
                                  });
                                } else {
                                  _handleSubmit();
                                }
                              },
                              style: ElevatedButton
                                  .styleFrom(
                                backgroundColor:
                                    AppColors
                                        .secondary,
                                padding: EdgeInsets
                                    .symmetric(
                                        vertical:
                                            12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                8)),
                              ),
                              child: Text(
                                (_isGameFinished &&
                                        !_isSuccess)
                                    ? "Retry"
                                    : buttonText,
                                style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: _onBackspace,
                            onLongPress:
                                _onClearAll,
                            child: Container(
                              padding:
                                  EdgeInsets.all(
                                      12),
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .redAccent,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            8),
                              ),
                              child: Icon(
                                Icons
                                    .backspace,
                                color:
                                    Colors.white,
                              ),
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
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 2)
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          char,
          style: TextStyle(
            fontSize: char == "SPC" ? 14 : 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}