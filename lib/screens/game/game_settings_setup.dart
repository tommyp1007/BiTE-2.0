import 'dart:io'; // Import added for Platform checking
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

// Internal Imports (Adjust paths if necessary)
import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart'; 
import '../../services/game_data_manager.dart'; 
import 'game_level_screen.dart'; 

class GameSettingsScreen extends StatefulWidget {
  final Function(double)? onBgmVolumeChanged;
  final Function(double)? onSfxVolumeChanged;
  final Function(bool)? onVibrationChanged;

  const GameSettingsScreen({
    Key? key, 
    this.onBgmVolumeChanged, 
    this.onSfxVolumeChanged,
    this.onVibrationChanged
  }) : super(key: key);

  @override
  _GameSettingsScreenState createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  final AudioPlayer _settingsPlayer = AudioPlayer();
  
  // Helpers for Resetting Data
  final GameDataManager _gameDataManager = GameDataManager();
  final SharedPreferencesHelper _prefsHelper = SharedPreferencesHelper();

  double _bgmVolume = 0.5;
  double _sfxVolume = 1.0;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _settingsPlayer.dispose();
    super.dispose();
  }

  // --- AUDIO HELPER ---
  void _playSound(String fileName, {double? volumeOverride}) async {
    double vol = volumeOverride ?? _sfxVolume;
    await _settingsPlayer.stop();
    await _settingsPlayer.setVolume(vol);
    await _settingsPlayer.play(AssetSource('audio/$fileName.mp3'));
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.5;
      _sfxVolume = prefs.getDouble('sfx_volume') ?? 1.0;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  void _updateBgmVolume(double value) async {
    setState(() => _bgmVolume = value);
    if (widget.onBgmVolumeChanged != null) widget.onBgmVolumeChanged!(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', value);
  }

  void _updateSfxVolume(double value) async {
    setState(() => _sfxVolume = value);
    if (widget.onSfxVolumeChanged != null) widget.onSfxVolumeChanged!(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', value);
  }

  // ⭐ UPDATED VIBRATION LOGIC
  void _toggleVibration(bool value) async {
    setState(() => _vibrationEnabled = value);
    widget.onVibrationChanged?.call(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    
    if (value) {
      // Logic: Stronger vibration for Android, standard haptics for iOS
      if (Platform.isAndroid) {
        // Standard buzz (Required for many Androids to feel it)
        HapticFeedback.vibrate(); 
      } else {
        // Taptic feedback (Nicer on iPhone)
        // Note: iPads usually do not have vibration hardware.
        HapticFeedback.mediumImpact(); 
      }
      
      _playSound('pop'); 
    }
  }

  // ⭐ RESET LOGIC: Confirmation Dialog
  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Reset Progress?", 
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)
        ),
        content: const Text(
          "Are you SURE you want to reset your game progress? You will LOSE your current data and return to Level 1. This action cannot be undone.",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await _performReset();
            },
            child: const Text("Reset", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // ⭐ RESET LOGIC: Critical Fix for Unresponsive Screen
  Future<void> _performReset() async {
    // 1. Reset Local Storage
    await _prefsHelper.resetGameProgress();
    
    // ⭐ CRITICAL: Manually set difficulty back to easy in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("difficulty", "easy");
    
    // 2. Reset Firebase (Cloud)
    await _gameDataManager.resetGameProgress();

    if (mounted) {
      // 3. Play sound feedback
      _playSound('correct'); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Game progress reset. Returning to Level Selection..."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        )
      );

      // 4. Navigate back to GameLevelScreen cleanly
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => GameLevelScreen()),
        (Route<dynamic> route) => false, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        // LayoutBuilder ensures we know screen dimensions for centering logic
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                // Forces the content to be at least the height of the screen
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  // Limits width for Tablets/Desktop so settings don't look stretched
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- Header (Back + Title) ---
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Image.asset('assets/images/back_icon.png', width: 40),
                              ),
                              const Text(
                                "SETTINGS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.blue, offset: Offset(2, 2), blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(width: 40), // Spacer to balance the Back Icon
                            ],
                          ),
                        ),

                        // --- Settings Container ---
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.secondary, width: 2),
                          ),
                          child: Column(
                            children: [
                              // --- BGM Volume ---
                              _buildSectionTitle("Music Volume"),
                              Row(
                                children: [
                                  const Icon(Icons.music_note, color: Colors.white),
                                  Expanded(
                                    child: Slider(
                                      value: _bgmVolume,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: AppColors.secondary,
                                      inactiveColor: Colors.white30,
                                      onChanged: _updateBgmVolume,
                                      onChangeEnd: (_) => _playSound('pop', volumeOverride: _bgmVolume),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      "${(_bgmVolume * 100).toInt()}%", 
                                      style: const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // --- SFX Volume ---
                              _buildSectionTitle("Sound Effects"),
                              Row(
                                children: [
                                  const Icon(Icons.touch_app, color: Colors.white),
                                  Expanded(
                                    child: Slider(
                                      value: _sfxVolume,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: AppColors.secondary,
                                      inactiveColor: Colors.white30,
                                      onChanged: _updateSfxVolume,
                                      onChangeEnd: (_) => _playSound('pop', volumeOverride: _sfxVolume),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      "${(_sfxVolume * 100).toInt()}%", 
                                      style: const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // --- Vibration Toggle ---
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle("Vibration", paddingBottom: 0),
                                  Switch(
                                    value: _vibrationEnabled,
                                    activeColor: AppColors.secondary,
                                    onChanged: _toggleVibration,
                                  ),
                                ],
                              ),

                              // Spacer replaced with SizedBox for scroll safety
                              const SizedBox(height: 40),
                              
                              // --- Reset Progress Button ---
                              const Divider(color: Colors.white30),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _confirmReset,
                                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                                  label: const Text(
                                    "RESET GAME PROGRESS", 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {double paddingBottom = 10.0}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: paddingBottom),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}