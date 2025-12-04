import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart'; // Import Helper

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
  final AudioPlayer _testSfxPlayer = AudioPlayer();
  final SharedPreferencesHelper _prefsHelper = SharedPreferencesHelper(); // Helper instance

  double _bgmVolume = 0.5;
  double _sfxVolume = 1.0;
  bool _vibrationEnabled = true;
  bool _isResetting = false; // To show loading during reset

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _testSfxPlayer.dispose();
    super.dispose();
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

    await _testSfxPlayer.setVolume(value);
    await _testSfxPlayer.stop();
    await _testSfxPlayer.play(AssetSource('audio/pop.mp3'));
  }

  void _toggleVibration(bool value) async {
    setState(() => _vibrationEnabled = value);
    widget.onVibrationChanged?.call(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    if (value) HapticFeedback.mediumImpact();
  }

  // --- RESET LOGIC START ---
  Future<void> _handleResetProgress() async {
    // 1. Show Confirmation Dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Reset Progress?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text("This will lock all levels except Level 1. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isResetting = true);

    try {
      // 2. Reset Local SharedPreferences
      await _prefsHelper.setUnlockedLevel(1);
      await _prefsHelper.setCurrentLevel(1);

      // 3. Reset Firebase Firestore
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'unlockedLevel': 1,
          'currentLevel': 1,
          // You can also reset score if you want: 'score': 0,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Game progress has been reset."))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error resetting: $e"))
        );
      }
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }
  // --- RESET LOGIC END ---

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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                            ),
                          ),
                          Text("${(_bgmVolume * 100).toInt()}%", style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                  
                      const SizedBox(height: 30),
                  
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
                            ),
                          ),
                          Text("${(_sfxVolume * 100).toInt()}%", style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                  
                      const SizedBox(height: 30),
                  
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

                      const SizedBox(height: 40),
                      const Divider(color: Colors.white30),
                      const SizedBox(height: 20),

                      // --- RESET BUTTON UI ---
                      _isResetting 
                        ? const CircularProgressIndicator(color: Colors.redAccent)
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _handleResetProgress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.9),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.delete_forever, color: Colors.white),
                              label: const Text(
                                "RESET GAME PROGRESS",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                      const SizedBox(height: 10),
                      const Text(
                        "Locks all levels and restarts from Level 1",
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
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