import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart'; // Ensure you have your user_model.dart file
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  bool _isLoading = false;

  // Main Sign Up Logic
  Future<void> _handleSignUp() async {
    String email = _emailCtrl.text.trim();
    String firstName = _firstNameCtrl.text.trim();
    String lastName = _lastNameCtrl.text.trim();
    String username = _usernameCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();
    String password = _passwordCtrl.text.trim();
    String confirmPassword = _confirmCtrl.text.trim();

    // 1. Validate inputs matching Java logic
    if (email.isEmpty || firstName.isEmpty || lastName.isEmpty || username.isEmpty || 
        phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showToast("Please fill in all the requirements");
      return;
    }

    if (password != confirmPassword) {
      _showToast("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Check Username Availability (Matches checkUsernameAvailability in Java)
      final usernameCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        _showToast("Username is already taken");
        setState(() => _isLoading = false);
        return;
      }

      // 3. Create User Account (Matches createUserAccount in Java)
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      if (cred.user != null) {
        // 4. Save User Info & Game State to Firestore (Matches saveUserInfo in Java)
        await _saveUserInfo(cred.user!.uid, firstName, lastName, username, phone, email);
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showToast("User already exists.");
      } else if (e.code == 'weak-password') {
        _showToast("Password should be at least 6 characters.");
      } else {
        _showToast("Sign Up failed: ${e.message}");
      }
      setState(() => _isLoading = false);
    } catch (e) {
      _showToast("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // Helper to save data to Firestore
  Future<void> _saveUserInfo(String userId, String fName, String lName, String uName, String phone, String email) async {
    try {
      // Initialize game state as per Java code
      int initialLevel = 1;
      String initialDifficulty = "easy";
      int initialUnlockedLevel = 1;

      // Using a Map directly to ensure field names match Firestore exactly
      Map<String, dynamic> userData = {
        "firstName": fName,
        "lastName": lName,
        "username": uName,
        "phone": phone,
        "email": email,
        "userId": userId,
        // Game State Fields
        "currentLevel": initialLevel,
        "difficulty": initialDifficulty,
        "unlockedLevel": initialUnlockedLevel
      };

      await FirebaseFirestore.instance.collection('users').doc(userId).set(userData);

      _showToast("You Have Successfully Signed Up");
      
      // Navigate to Sign In (Matches navigateToSignIn in Java)
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => SignInScreen())
        );
      }

    } catch (e) {
      _showToast("Error saving user info: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Back Arrow
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignInScreen())), 
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 10.0),
                    child: Image.asset('assets/images/back_icon.png', width: 40, height: 40),
                  ),
                ),
              ),

              Image.asset('assets/images/bite_icon2_bright.png', width: 100, height: 100),
              SizedBox(height: 10),
              Text("Sign Up", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: AppColors.white)),
              
              SizedBox(height: 10),
              _buildInput("First Name", _firstNameCtrl),
              _buildInput("Last Name", _lastNameCtrl),
              _buildInput("Username", _usernameCtrl),
              _buildInput("Email", _emailCtrl, isEmail: true),
              _buildInput("Phone Number", _phoneCtrl, isPhone: true),
              _buildInput("Password", _passwordCtrl, obscure: true),
              _buildInput("Confirm Password", _confirmCtrl, obscure: true),
              
              SizedBox(height: 20),
              _isLoading 
                ? CircularProgressIndicator(color: AppColors.white) 
                : ElevatedButton(
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary, // @color/colorSecondary
                      minimumSize: Size(double.infinity, 50)
                    ),
                    child: Text("Sign Up", style: TextStyle(fontSize: 18, color: AppColors.white)),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl, {bool obscure = false, bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
        style: TextStyle(color: AppColors.black),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
          hintStyle: TextStyle(color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}