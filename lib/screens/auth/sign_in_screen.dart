import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart'; // Ensure this file exists in lib/theme/
import 'sign_up_screen.dart';
import '../home_screen.dart'; // Ensure lib/screens/home_screen.dart exists

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Controllers
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  
  // State
  bool _isLoading = false;

  // Logic matching SignInActivity.java
  Future<void> _signIn() async {
    String username = _usernameCtrl.text.trim();
    String password = _passwordCtrl.text.trim();

    // 1. Validation
    if (username.isEmpty || password.isEmpty) {
      _showToast("Please enter both username and password.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Search for the user by username in Firestore
      // NOTE: Your Firestore Rules must allow reading the 'users' collection for this to work!
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // 3. Get the user's email from Firestore
        // Java: DocumentSnapshot documentSnapshot = querySnapshot.getDocuments().get(0);
        var userDoc = snapshot.docs.first;
        String? email = userDoc.data().containsKey('email') ? userDoc.get('email') : null;

        if (email != null) {
          // 4. Sign in with the email and password
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email, 
            password: password
          );

          _showToast("Successfully signed in!");
          
          // 5. Navigate to MainActivity (HomeScreen)
          // Java: Intent intent = new Intent(SignInActivity.this, MainActivity.class);
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (_) => HomeScreen()), 
              (route) => false
            );
          }
        } else {
          _showToast("Email not found for this user.");
        }

      } else {
        // Username not found
        _showToast("Username not found.");
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'wrong-password' || e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _showToast("Incorrect password or user details.");
      } else {
        _showToast("Sign in failed: ${e.message}");
      }
      print("Auth Error: ${e.code} - ${e.message}");
    } catch (e) {
      // General errors (Likely Firestore Permission denied or Network)
      _showToast("Error fetching user data.");
      print("General Error: $e"); // Check your Run console for this!
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Matches Java onBackPressed logic
  void _onBackPressed() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => HomeScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back Arrow
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: _onBackPressed,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 16.0),
                      child: Image.asset('assets/images/back_icon.png', width: 40, height: 40),
                    ),
                  ),
                ),
                
                // Logo
                Image.asset('assets/images/bite_icon2_bright.png', width: 100, height: 100),
                SizedBox(height: 20),
                
                // Title
                Text(
                  "BiTE", 
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.white)
                ),
                SizedBox(height: 40),
                
                // Username Input
                _buildInput("Username", _usernameCtrl),
                SizedBox(height: 20),
                
                // Password Input
                _buildInput("Password", _passwordCtrl, obscure: true),
                
                SizedBox(height: 20),
                
                // Buttons / Loading
                if (_isLoading) 
                  CircularProgressIndicator(color: AppColors.white) 
                else ...[
                  // Sign In Button
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent, // Corresponds to your XML tint
                      minimumSize: Size(double.infinity, 50)
                    ),
                    child: Text("Sign In", style: TextStyle(fontSize: 18, color: AppColors.white)),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Sign Up Button
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary, // Corresponds to your XML tint
                      minimumSize: Size(double.infinity, 50)
                    ),
                    child: Text("Sign Up", style: TextStyle(fontSize: 18, color: AppColors.white)),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: AppColors.black),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white, // Matches @drawable/background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: Colors.grey), // @android:color/darker_gray
      ),
    );
  }
}