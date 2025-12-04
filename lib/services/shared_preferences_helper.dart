import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _keyCurrentLevel = "current_level";
  static const String _keyDifficulty = "difficulty";
  static const String _keyUnlockedLevel = "unlocked_level";

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

  // Used by the Reset Button to lock levels back to 1
  Future<void> setUnlockedLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUnlockedLevel, level);
  }

  Future<int> getUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUnlockedLevel) ?? 1; // Default to level 1 unlocked
  }
}