import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import needed for settings
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart'; 
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart'; 

void main() async {
  // 1. Initialize Bindings
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 2. Preserve Native Splash
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 3. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ⭐ NEW: Enable Offline Persistence & Sync
  // This allows the app to work offline and sync data when online automatically.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, 
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 4. Run App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BiTE Translator',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white), 
        ),
      ),
      
      // Start with the Splash Screen
      home: const SplashScreen(),
    );
  }
}