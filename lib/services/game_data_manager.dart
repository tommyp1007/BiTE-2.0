import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameDataManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Real-time Stream for Multi-device Sync
  Stream<DocumentSnapshot>? getUserDataStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection("users").doc(user.uid).snapshots();
    }
    return null;
  }

  // Save game state
  // ⭐ NOTE: Because we enabled persistence in main.dart, 
  // this function works OFFLINE. Data is cached and syncs when online.
  Future<void> saveGameState(int level, int score, String difficulty, int unlockedLevel) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection("users").doc(user.uid).set({
          "currentLevel": level,
          "score": score,
          "difficulty": difficulty,
          "unlockedLevel": unlockedLevel
        }, SetOptions(merge: true)); 
      } catch (e) {
        print("Error saving game state: $e");
      }
    }
  }

  // Save Stars for a specific Level
  Future<void> saveLevelStars(int level, int stars) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection("users").doc(user.uid).set({
          "levelStars": {
            "$level": stars
          }
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving stars: $e");
      }
    }
  }

  // ⭐ FIXED: Reset now forces difficulty to 'easy'
  Future<void> resetGameProgress() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection("users").doc(user.uid).update({
          "currentLevel": 1,
          "unlockedLevel": 1,
          "difficulty": "easy", // Added this to fix the 'Locked Screen' bug
          "score": 0, 
          "levelStars": {}, 
        });
      } catch (e) {
        print("Error resetting game progress: $e");
      }
    }
  }
}