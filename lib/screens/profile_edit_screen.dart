import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import 'auth/sign_in_screen.dart';
import 'home_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _loadUserProfile();
    }
  }

  // Load data from Firestore (Matches Java: loadUserProfile)
  Future<void> _loadUserProfile() async {
    _emailCtrl.text = user!.email ?? '';
    try {
      DocumentSnapshot doc = await db.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _firstNameCtrl.text = doc.get('firstName') ?? '';
          _lastNameCtrl.text = doc.get('lastName') ?? '';
          _usernameCtrl.text = doc.get('username') ?? '';
          _phoneCtrl.text = doc.get('phone') ?? '';
        });
      } else {
        _showToast("User data not found.");
      }
    } catch (e) {
      _showToast("Failed to load user data.");
    }
  }

  // Matches Java: saveProfileChanges logic flow
  Future<void> _saveProfileChanges() async {
    String firstName = _firstNameCtrl.text.trim();
    String lastName = _lastNameCtrl.text.trim();
    String username = _usernameCtrl.text.trim();
    String email = _emailCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();
    String currentPassword = _currentPasswordCtrl.text.trim();
    String newPassword = _newPasswordCtrl.text.trim();
    String confirmPassword = _confirmPasswordCtrl.text.trim();

    // 1. Validation
    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty || email.isEmpty || phone.isEmpty) {
      _showToast("All fields are required.");
      return;
    }

    if (currentPassword.isNotEmpty && (newPassword.isEmpty || confirmPassword.isEmpty)) {
      _showToast("Please enter the new password and confirm it.");
      return;
    }

    if (newPassword != confirmPassword) {
      _showToast("New password and confirm password do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Check if current password is provided (Logic from Java)
      if (currentPassword.isNotEmpty) {
        // Re-authenticate user
        AuthCredential credential = EmailAuthProvider.credential(email: user!.email!, password: currentPassword);
        
        try {
          await user!.reauthenticateWithCredential(credential);

          // If re-auth success, check if we need to update password
          if (newPassword.isNotEmpty) {
            await user!.updatePassword(newPassword);
            // Password updated, now update profile details
            await _updateUserProfile(firstName, lastName, username, email, phone);
          } else {
            // No new password, just update profile details
            await _updateUserProfile(firstName, lastName, username, email, phone);
          }
        } on FirebaseAuthException catch (e) {
          setState(() => _isLoading = false);
          _showToast("Current password is incorrect."); // Matches Java error handling
        }
      } else {
        // No current password entered, just update profile directly
        await _updateUserProfile(firstName, lastName, username, email, phone);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast("Error: ${e.toString()}");
    }
  }

  // Matches Java: updateUserProfile
  Future<void> _updateUserProfile(String first, String last, String userN, String email, String phone) async {
    // Check if email needs update
    if (email != user!.email) {
      try {
        // Note: Flutter recommends verifyBeforeUpdateEmail, but logic follows Java's updateEmail flow
        await user!.verifyBeforeUpdateEmail(email); 
        // After email update init, update Firestore
        await _updateFirestoreProfile(first, last, userN, email, phone);
      } catch (e) {
        setState(() => _isLoading = false);
        _showToast("Failed to update email: $e");
      }
    } else {
      // Email unchanged
      await _updateFirestoreProfile(first, last, userN, email, phone);
    }
  }

  // Matches Java: updateFirestoreProfile
  Future<void> _updateFirestoreProfile(String first, String last, String userN, String email, String phone) async {
    try {
      await db.collection('users').doc(user!.uid).update({
        'firstName': first,
        'lastName': last,
        'username': userN,
        'email': email,
        'phone': phone,
      });

      setState(() => _isLoading = false);
      _showToast("Profile updated successfully!");

      // Navigate to Home (Matches Java: startActivity MainActivity)
      _navigateToHome();

    } catch (e) {
      setState(() => _isLoading = false);
      _showToast("Failed to update profile.");
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (route) => false,
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Handle Back Button (Matches Java: onBackPressed)
  Future<bool> _onWillPop() async {
    _navigateToHome();
    return false; // Prevent default pop, since we handled navigation manually
  }

  @override
  Widget build(BuildContext context) {
    // PopScope (or WillPopScope) handles the physical back button logic from Android
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: _navigateToHome, // Back arrow now goes to Home, matching Java finish/intent logic
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset('assets/images/back_icon.png', width: 40, height: 40),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Image.asset('assets/images/edit_user.png', width: 70, height: 70),
                      SizedBox(height: 10),
                      Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 20),

                      _buildField("First Name", _firstNameCtrl),
                      _buildField("Last Name", _lastNameCtrl),
                      _buildField("Username", _usernameCtrl),
                      _buildField("Email", _emailCtrl, isEmail: true),
                      _buildField("Phone Number", _phoneCtrl, isPhone: true),
                      _buildField("Current Password", _currentPasswordCtrl, obscure: true),
                      _buildField("New Password", _newPasswordCtrl, obscure: true),
                      _buildField("Confirm Password", _confirmPasswordCtrl, obscure: true),

                      SizedBox(height: 20),
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton(
                              onPressed: _saveProfileChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                minimumSize: Size(double.infinity, 50),
                              ),
                              child: Text("Update Profile", style: TextStyle(color: Colors.white)),
                            ),

                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => SignInScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text("Logout", style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Bottom Panel placeholder
              Container(height: 50, color: AppColors.primaryDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController ctrl, {bool obscure = false, bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}