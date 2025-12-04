import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart'; 

class GameSettingsScreen extends StatefulWidget {
  // Add callbacks to notify parent immediately
  final Function(double)? onBgmVolumeChanged;
  final Function(double)? onSfxVolumeChanged;
  final Function(bool)? onVibrationChanged; // NEW CALLBACK

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
  double _bgmVolume = 0.5;
  double _sfxVolume = 1.0;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
    
    if (widget.onBgmVolumeChanged != null) {
      widget.onBgmVolumeChanged!(value);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', value);
  }

  void _updateSfxVolume(double value) async {
    setState(() => _sfxVolume = value);
    
    if (widget.onSfxVolumeChanged != null) {
      widget.onSfxVolumeChanged!(value);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', value);
  }

  void _toggleVibration(bool value) async {
    setState(() => _vibrationEnabled = value);

    // Notify Game Screen immediately
    if (widget.onVibrationChanged != null) {
      widget.onVibrationChanged!(value);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
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
                          ),
                        ),
                        Text("${(_sfxVolume * 100).toInt()}%", style: const TextStyle(color: Colors.white)),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- Vibration ---
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