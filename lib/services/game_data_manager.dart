import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameState {
  final int level;
  final int score;
  final String difficulty;
  final int unlockedLevel;

  GameState({
    required this.level, 
    required this.score, 
    required this.difficulty, 
    required this.unlockedLevel
  });
}

class GameDataManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save game state
  Future<void> saveGameState(int level, int score, String difficulty, int unlockedLevel) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection("users").doc(user.uid).update({
          "currentLevel": level,
          "score": score,
          "difficulty": difficulty,
          "unlockedLevel": unlockedLevel
        });
        print("Game state saved successfully");
      } catch (e) {
        print("Error saving game state: $e");
      }
    } else {
      print("User not logged in");
    }
  }

  // Load game state
  Future<GameState?> loadGameState() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection("users").doc(user.uid).get();
        if (doc.exists) {
          return GameState(
            level: doc.get("currentLevel") ?? 1,
            score: doc.get("score") ?? 0,
            difficulty: doc.get("difficulty") ?? "easy",
            unlockedLevel: doc.get("unlockedLevel") ?? 1
          );
        }
      } catch (e) {
        print("Error loading game state: $e");
      }
    }
    return null;
  }

  // UPDATED RESET HELPER
  Future<void> resetGameProgress() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection("users").doc(user.uid).update({
          "currentLevel": 1,
          "unlockedLevel": 1,
          "score": 0,
          "levelStars": {}, // Clear the stars map
        });
        print("Game progress reset successfully");
      } catch (e) {
        print("Error resetting game progress: $e");
        throw e; 
      }
    }
  }
}