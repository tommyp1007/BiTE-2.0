import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  bool _isLoading = false;
  
  // Visibility States
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  Future<void> _handleSignUp() async {
    // Unfocus to commit text changes
    FocusScope.of(context).unfocus();

    String email = _emailCtrl.text.trim();
    String firstName = _firstNameCtrl.text.trim();
    String lastName = _lastNameCtrl.text.trim();
    String username = _usernameCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();
    String password = _passwordCtrl.text.trim();
    String confirmPassword = _confirmCtrl.text.trim();

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
      final usernameCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        _showToast("Username is already taken");
        setState(() => _isLoading = false);
        return;
      }

      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      if (cred.user != null) {
        await _saveUserInfo(cred.user!.uid, firstName, lastName, username, phone, email);
        
        // --- AUTOFILL TRIGGER ---
        TextInput.finishAutofillContext(shouldSave: true); 
        // ------------------------
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

  Future<void> _saveUserInfo(String userId, String fName, String lName, String uName, String phone, String email) async {
    try {
      int initialLevel = 1;
      String initialDifficulty = "easy";
      int initialUnlockedLevel = 1;

      Map<String, dynamic> userData = {
        "firstName": fName,
        "lastName": lName,
        "username": uName,
        "phone": phone,
        "email": email,
        "userId": userId,
        "currentLevel": initialLevel,
        "difficulty": initialDifficulty,
        "unlockedLevel": initialUnlockedLevel
      };

      await FirebaseFirestore.instance.collection('users').doc(userId).set(userData);

      _showToast("You Have Successfully Signed Up");
      
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
        // LayoutBuilder ensures we know the screen height for centering logic
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                // Forces the content to be at least as tall as the screen
                // This makes 'Center' work, but allows scrolling if content overflows
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  // Limits width on large devices (Tablets/Landscape)
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: IntrinsicHeight(
                      child: AutofillGroup(
                        onDisposeAction: AutofillContextAction.commit,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Back Button
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 10),
                                child: GestureDetector(
                                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignInScreen())), 
                                  child: Image.asset(
                                    'assets/images/back_icon.png', 
                                    width: 40, 
                                    height: 40
                                  ),
                                ),
                              ),
                            ),
                          
                            Image.asset('assets/images/bite_icon.png', width: 100, height: 100),
                            SizedBox(height: 10),
                            
                            Text(
                              "Sign Up", 
                              style: TextStyle(
                                fontSize: 30, // Slightly larger for better hierarchy
                                fontWeight: FontWeight.bold, 
                                color: AppColors.white
                              )
                            ),
                            
                            SizedBox(height: 20),

                            _buildInput("First Name", _firstNameCtrl, autofillHints: [AutofillHints.givenName]),
                            _buildInput("Last Name", _lastNameCtrl, autofillHints: [AutofillHints.familyName]),
                            _buildInput("Username", _usernameCtrl, autofillHints: [AutofillHints.username]),
                            _buildInput("Email", _emailCtrl, isEmail: true, autofillHints: [AutofillHints.email]),
                            _buildInput("Phone Number", _phoneCtrl, isPhone: true, autofillHints: [AutofillHints.telephoneNumber]),
                            
                            _buildInput(
                              "Password", 
                              _passwordCtrl, 
                              isPassword: true,
                              isVisible: _isPasswordVisible,
                              onVisibilityToggle: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              autofillHints: [AutofillHints.newPassword] 
                            ),

                            _buildInput(
                              "Confirm Password", 
                              _confirmCtrl, 
                              isPassword: true,
                              isVisible: _isConfirmVisible,
                              onVisibilityToggle: () {
                                setState(() {
                                  _isConfirmVisible = !_isConfirmVisible;
                                });
                              },
                              autofillHints: [AutofillHints.newPassword]
                            ),
                            
                            SizedBox(height: 30),
                            
                            if (_isLoading) 
                              CircularProgressIndicator(color: AppColors.white) 
                            else
                              ElevatedButton(
                                onPressed: _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  minimumSize: Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)
                                  )
                                ),
                                child: Text("Sign Up", style: TextStyle(fontSize: 18, color: AppColors.white)),
                              ),

                            // Extra bottom padding so it doesn't touch the screen edge on scroll
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInput(
    String hint, 
    TextEditingController ctrl, 
    {
      bool isPassword = false, 
      bool isVisible = false,
      VoidCallback? onVisibilityToggle,
      bool isEmail = false, 
      bool isPhone = false, 
      Iterable<String>? autofillHints
    }) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0), // Increased spacing slightly
      child: TextField(
        controller: ctrl,
        obscureText: isPassword ? !isVisible : false,
        autofillHints: autofillHints,
        keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none
          ),
          hintStyle: TextStyle(color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Comfortable touch target
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        ),
      ),
    );
  }
}