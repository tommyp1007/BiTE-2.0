import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Autofill
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import 'sign_up_screen.dart';
import '../home_screen.dart';

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
  bool _isPasswordVisible = false;

  Future<void> _signIn() async {
    // Dismiss keyboard to commit the text to the controllers
    FocusScope.of(context).unfocus();

    String username = _usernameCtrl.text.trim();
    String password = _passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showToast("Please enter both username and password.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Search for the user by username in Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var userDoc = snapshot.docs.first;
        String? email = userDoc.data().containsKey('email') ? userDoc.get('email') : null;

        if (email != null) {
          // 2. Sign in with the email (found via username) and password
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password
          );

          // --- AUTOFILL TRIGGER ---
          TextInput.finishAutofillContext(shouldSave: true);
          // ------------------------

          _showToast("Successfully signed in!");

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
        _showToast("Username not found.");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _showToast("Incorrect password or user details.");
      } else {
        _showToast("Sign in failed: ${e.message}");
      }
    } catch (e) {
      _showToast("Error fetching user data.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
        // LayoutBuilder gives us the screen height constraints
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                // This ensures the content is at least as tall as the screen
                // forcing the 'Center' logic to work even when scrolling is possible
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  // This Container limits width on Tablets/iPads so it doesn't look stretched
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: IntrinsicHeight(
                      child: AutofillGroup(
                        onDisposeAction: AutofillContextAction.commit,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Back Button - Positioned slightly differently for better layout
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 20),
                                child: GestureDetector(
                                  onTap: _onBackPressed,
                                  child: Image.asset(
                                    'assets/images/back_icon.png', 
                                    width: 40, 
                                    height: 40
                                  ),
                                ),
                              ),
                            ),
                            
                            // Spacer to push content towards middle if screen is tall
                            const SizedBox(height: 20),

                            Image.asset('assets/images/bite_icon.png', width: 100, height: 100),
                            
                            SizedBox(height: 20),
                            
                            Text(
                              "BiTE",
                              style: TextStyle(
                                fontSize: 36, 
                                fontWeight: FontWeight.bold, 
                                color: AppColors.white
                              ),
                            ),
                            
                            SizedBox(height: 40),
                            
                            // Username
                            _buildInput(
                              "Username",
                              _usernameCtrl,
                              autofillHints: [AutofillHints.username],
                              isLast: false
                            ),
                            
                            SizedBox(height: 20),
                            
                            // Password
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
                              autofillHints: [AutofillHints.password],
                              isLast: true
                            ),
                            
                            SizedBox(height: 30),
                            
                            if (_isLoading)
                              CircularProgressIndicator(color: AppColors.white)
                            else ...[
                              ElevatedButton(
                                onPressed: _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF914D),
                                  minimumSize: Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)
                                  )
                                ),
                                child: Text("Sign In", style: TextStyle(fontSize: 18, color: AppColors.white)),
                              ),
                              
                              SizedBox(height: 15),
                              
                              ElevatedButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpScreen())),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  minimumSize: Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)
                                  )
                                ),
                                child: Text("Sign Up", style: TextStyle(fontSize: 18, color: AppColors.white)),
                              ),
                            ],
                            
                            // Bottom spacing to ensure it doesn't touch the very bottom
                            const SizedBox(height: 40),
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
      Iterable<String>? autofillHints,
      bool isLast = false
    }) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword ? !isVisible : false,
      autofillHints: autofillHints,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onEditingComplete: isLast ? _signIn : null,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Slightly more modern curve
          borderSide: BorderSide.none
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Larger touch target
        hintStyle: TextStyle(color: Colors.grey),
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
    );
  }
}