import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart'; 
import '../../services/game_data_manager.dart'; 
// ⭐ Import GameLevelScreen to navigate back to it
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

  // 🔥 REMOVED THE DUPLICATE dispose() METHOD HERE (Was line 45-49)
  // @override
  // void dispose() {
  //   _settingsPlayer.dispose();
  //   super.dispose();
  // }

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

  void _toggleVibration(bool value) async {
    setState(() => _vibrationEnabled = value);
    widget.onVibrationChanged?.call(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    if (value) {
      HapticFeedback.mediumImpact();
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
          "Are you SURE you want to reset your game progress? You will LOSE your current data. This action cannot be undone.",
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

  // ⭐ RESET LOGIC: Execution & Navigation
  Future<void> _performReset() async {
    // 1. Reset Local Storage
    await _prefsHelper.resetGameProgress();
    
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

      // 4. Navigate back to GameLevelScreen automatically
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => GameLevelScreen()),
        (Route<dynamic> route) => route.isFirst, // Keeps the Main Menu (if it exists) in the stack
      );
    }
  }

  // This is the correct, singular definition of dispose()
  @override
  void dispose() {
    _settingsPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset('assets/images/back_icon.png', width: 40),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "SETTINGS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.blue, offset: Offset(2, 2), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
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
                        Text("${(_bgmVolume * 100).toInt()}%", style: const TextStyle(color: Colors.white)),
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
                        Text("${(_sfxVolume * 100).toInt()}%", style: const TextStyle(color: Colors.white)),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- Vibration Toggle ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle("Vibration"),
                        Switch(
                          value: _vibrationEnabled,
                          activeColor: AppColors.secondary,
                          onChanged: _toggleVibration,
                        ),
                      ],
                    ),

                    const Spacer(),
                    
                    // --- Reset Progress Button ---
                    const Divider(color: Colors.white30),
                    const SizedBox(height: 10),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
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