import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _keyCurrentLevel = "current_level";
  static const String _keyDifficulty = "difficulty";
  static const String _keyUnlockedLevel = "unlocked_level";
  static const String _keyLevelStarsPrefix = "level_stars_"; // Prefix for level stars

  Future<void> setCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    if (level >= 1 && level <= 15) {
      await prefs.setInt(_keyCurrentLevel, level);
    }
  }

  Future<int> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentLevel) ?? 1;
  }

  Future<void> saveDifficulty(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDifficulty, difficulty);
  }

  Future<String> getSavedDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDifficulty) ?? "easy";
  }

  Future<void> setUnlockedLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUnlockedLevel, level);
  }

  Future<int> getUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUnlockedLevel) ?? 1; 
  }

  // --- NEW: STAR RATING METHODS ---

  // Save stars for a specific level
  Future<void> setStarsForLevel(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyLevelStarsPrefix$level', stars);
  }

  // Get stars for a specific level (defaults to 0)
  Future<int> getStarsForLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyLevelStarsPrefix$level') ?? 0;
  }

  // Reset all stars (Used when resetting game progress)
  Future<void> resetAllStars() async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming max level is 15
    for (int i = 1; i <= 15; i++) {
      await prefs.remove('$_keyLevelStarsPrefix$i');
    }
  }
}