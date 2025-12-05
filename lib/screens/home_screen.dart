import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart'; 
import 'package:device_info_plus/device_info_plus.dart'; // Optional: helps checking android version, but we can do it with logic below

import '../../theme/app_colors.dart';
import '../../services/shared_preferences_helper.dart';
import '../widgets/common_layouts.dart';
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
    // Trigger permission request immediately on load
    _requestInitialPermissions();
  }

  // ⭐ UPDATED: Robust Permission Request
  Future<void> _requestInitialPermissions() async {
    List<Permission> permissionsToRequest = [
      Permission.microphone,
      Permission.location,     
      Permission.notification, 
    ];

    if (Platform.isAndroid) {
      // Logic for Android 13+ vs Older Androids
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ uses granular permissions
        permissionsToRequest.addAll([
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ]);
      } else {
        // Android 12 and below uses standard storage permission
        permissionsToRequest.add(Permission.storage);
      }
    } else {
      // iOS
      permissionsToRequest.addAll([
        Permission.storage, 
        Permission.photos
      ]);
    }

    // Request all accumulated permissions
    Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();

    // Debugging print
    print("Permissions request result: $statuses");
  }

  void _checkUserStatus() {
    currentUser = _auth.currentUser;
    setState(() => isInGuestMode = (currentUser == null));

    if (!isInGuestMode) {
      _loadGameStateFromFirestore(currentUser!.uid);
      _fetchFirstNameFromFirestore(currentUser!.uid);
    }
  }

  void _loadGameStateFromFirestore(String userId) async {
    try {
      // By enabling persistence in main.dart, this works offline too!
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        await _prefs.setCurrentLevel(doc.get('currentLevel') ?? 1);
        await _prefs.saveDifficulty(doc.get('difficulty') ?? 'easy');
        await _prefs.setUnlockedLevel(doc.get('unlockedLevel') ?? 1);
      }
    } catch (_) {}
  }

  void _fetchFirstNameFromFirestore(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        String? firstName = doc.get('firstName');
        setState(() {
          welcomeText = firstName != null && firstName.isNotEmpty
              ? "Hi! Welcome, $firstName"
              : "Hi! Welcome, ${currentUser?.email ?? 'User'}";
        });
      }
    } catch (_) {}
  }

  void _promptSignIn() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Please sign in to access this feature")));
    Navigator.push(context, MaterialPageRoute(builder: (_) => SignInScreen()));
  }

  void _handleGridClick(String title, Widget page) {
    if (isInGuestMode && (title == "Word Guess" || title == "Vocabulary Learning")) {
      _promptSignIn();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _handleGuestLoginButton() async {
    if (isInGuestMode) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SignInScreen()));
    } else {
      await _auth.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    }
  }

  // Custom Button Widget for consistent look
  Widget _buildAuthButton(bool isGuest, VoidCallback onTap) {
    final Color btnColor = const Color(0xFFA0522D); 

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 110,
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 2,
            )
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2), // White border gap
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isGuest ? "Sign In" : "Sign Out",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isGuest)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 14, color: btnColor),
                )
              else
                const Icon(Icons.logout, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isiOS = Platform.isIOS;

    return Scaffold(
      backgroundColor: AppColors.primary,
      bottomNavigationBar: isiOS ? null : BottomNavPanel(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ------------------- TOP HEADER -------------------
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Image.asset('assets/images/bite_icon.png', width: 50, height: 50),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "BiTE Translator",
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  _buildAuthButton(isInGuestMode, _handleGuestLoginButton),
                ],
              ),
            ),

            // ------------------- MIDDLE SECTION -------------------
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      // Ensures content takes full available height for centering
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        // Limits width on Tablets/Desktop
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 500),
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              
                              // User Icon
                              GestureDetector(
                                onTap: () {
                                  if (isInGuestMode) _promptSignIn();
                                  else {
                                    Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => ProfileEditScreen()));
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                                    ]
                                  ),
                                  child: Image.asset('assets/images/user_icon.png', width: 80, height: 80),
                                ),
                              ),

                              SizedBox(height: 16),

                              // Welcome Text
                              GestureDetector(
                                onTap: () {
                                  if (isInGuestMode) _promptSignIn();
                                  else {
                                    Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => ProfileEditScreen()));
                                  }
                                },
                                child: Text(
                                  welcomeText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4)
                                    ]
                                  ),
                                ),
                              ),

                              SizedBox(height: 30),

                              // Grid Items
                              GridView.builder(
                                shrinkWrap: true, // Necessary inside ScrollView
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: _gridItems.length,
                                itemBuilder: (context, index) {
                                  final item = _gridItems[index];
                                  return Card(
                                    color: AppColors.secondary,
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: InkWell(
                                      onTap: () => _handleGridClick(item['title'], item['page']),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/${item['img']}',
                                            width: 65,
                                            height: 65,
                                            fit: BoxFit.contain,
                                          ),
                                          SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(
                                              item['title'],
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              // Extra spacing at bottom of scrollable area
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ------------------- BOTTOM TRADEMARK -------------------
            Padding(
              padding: EdgeInsets.only(bottom: isiOS ? 20 : 10, top: 10),
              child: Opacity(
                opacity: 0.8,
                child: Text(
                  "Developed by: TOMMY ANAK PEYEI",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}