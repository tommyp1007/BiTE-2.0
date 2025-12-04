plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bite_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Suppress warnings from third-party libraries
        allWarningsAsErrors = false
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
        // Show deprecation and unchecked warnings, but don't fail build
        freeCompilerArgs += listOf(
            "-Xlint:deprecation",
            "-Xlint:unchecked"
        )
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID
        applicationId = "com.example.bite_flutter"
        // Min and target SDK versions
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing config (for release builds, you can add your own later)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
