import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart'; // Not strictly needed here anymore as BottomNav handles exit
import 'package:permission_handler/permission_handler.dart'; 

import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart';
import '../widgets/common_layouts.dart'; // Ensure this points to the file above
import 'auth/sign_in_screen.dart';
import 'profile_edit_screen.dart';
import 'translator/text_translator_screen.dart';
import 'dictionary/dictionary_section_screen.dart';
import 'vocabulary/vocabulary_testing_screen.dart';
import 'game/word_guess_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SharedPreferencesHelper _prefs = SharedPreferencesHelper();

  User? currentUser;
  bool isInGuestMode = true;
  String welcomeText = "Hi! Welcome, Guest";

  // Grid Data
  final List<Map<String, dynamic>> _gridItems = [
    {"title": "Text Translator", "img": "text_translator.png", "page": TextTranslatorScreen()},
    {"title": "Dictionary Time", "img": "dictionary_section.png", "page": DictionarySectionScreen()},
    {"title": "Vocabulary Learning", "img": "vocab_learning.png", "page": VocabularyTestingScreen()},
    {"title": "Word Guess", "img": "word_guess.png", "page": WordGuessEntryScreen()},
  ];

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _requestInitialPermissions();
  }

  Future<void> _requestInitialPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone, 
      Permission.storage, 
      Permission.notification,
    ].request();

    if (statuses[Permission.microphone]!.isPermanentlyDenied) {
      // Handle denied permissions
    }
  }

  void _checkUserStatus() {
    currentUser = _auth.currentUser;
    setState(() {
      isInGuestMode = currentUser == null;
    });

    if (!isInGuestMode) {
      _loadGameStateFromFirestore(currentUser!.uid);
      _fetchFirstNameFromFirestore(currentUser!.uid);
    } else {
      setState(() => welcomeText = "Hi! Welcome, Guest");
    }
  }

  void _loadGameStateFromFirestore(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        int currentLevel = doc.get('currentLevel') ?? 1;
        String difficulty = doc.get('difficulty') ?? 'easy';
        int unlockedLevel = doc.get('unlockedLevel') ?? 1;

        await _prefs.setCurrentLevel(currentLevel);
        await _prefs.saveDifficulty(difficulty);
        await _prefs.setUnlockedLevel(unlockedLevel);
      }
    } catch (e) {
      print("Error loading game state: $e");
    }
  }

  void _fetchFirstNameFromFirestore(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        String? firstName = doc.get('firstName');
        setState(() {
          if (firstName != null && firstName.isNotEmpty) {
            welcomeText = "Hi! Welcome, $firstName";
          } else {
            welcomeText = "Hi! Welcome, ${currentUser?.email ?? 'User'}";
          }
        });
      }
    } catch (e) {
      setState(() => welcomeText = "Hi! Welcome, ${currentUser?.email ?? 'User'}");
    }
  }

  void _handleGridClick(String title, Widget page) {
    if (isInGuestMode) {
      if (title == "Word Guess" || title == "Vocabulary Learning") {
        _promptSignIn();
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      }
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  void _promptSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please sign in to access this feature")));
    Navigator.push(context, MaterialPageRoute(builder: (_) => SignInScreen()));
  }

  void _handleGuestLoginButton() async {
    if (isInGuestMode) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SignInScreen()));
    } else {
      await _auth.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      // IMPORTANT: BottomNavPanel is moved here to ensure it stays at the bottom
      bottomNavigationBar: BottomNavPanel(), 
      body: SafeArea(
        bottom: false, // We let the bottomNavigationBar handle the bottom safe area
        child: Column(
          children: [
            // 1. App Header
            Container(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Image.asset('assets/images/bite_icon2_bright.png', width: 60, height: 60, fit: BoxFit.contain),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "BiTE Translator", 
                      style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)
                    )
                  ),
                  GestureDetector(
                    onTap: _handleGuestLoginButton,
                    child: Image.asset(
                      isInGuestMode ? 'assets/images/loginbutton.png' : 'assets/images/logoutbutton.png',
                      width: 120, height: 40
                    ),
                  ),
                ],
              ),
            ),

            // 2. User Profile Icon
            GestureDetector(
              onTap: () {
                if (isInGuestMode) _promptSignIn();
                else Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileEditScreen()));
              },
              child: Image.asset('assets/images/user_icon.png', width: 40, height: 40),
            ),
            SizedBox(height: 8),

            // 3. Welcome Text
            GestureDetector(
              onTap: () {
                if (isInGuestMode) _promptSignIn();
                else Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileEditScreen()));
              },
              child: Text(welcomeText, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            // 4. Grid View
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0, 
                ),
                itemCount: _gridItems.length,
                itemBuilder: (context, index) {
                  final item = _gridItems[index];
                  return Card(
                    color: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      onTap: () => _handleGridClick(item['title'], item['page']),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/${item['img']}', 
                            width: 60, height: 60, 
                            errorBuilder: (c,e,s) => Icon(Icons.image, size: 50, color: Colors.white)
                          ),
                          SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              item['title'], 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 5. Trademark (This sits right above the bottom nav bar now)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text("Developed by: TOMMY ANAK PEYEI", style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}