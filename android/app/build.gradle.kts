plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.egypt.yabaladi_rebuild"
    compileSdk = flutter.compileSdkVersion
    
    // [v3 — 2026-10-14] Firebase packages تتطلب NDK 27
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.egypt.yabaladi_rebuild"
        // [v3] firebase_auth يتطلب minSdk 23 (كان 21)
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // [v2 — 2026-10-14] Kotlin 1.9 syntax — متوافق مع Flutter Plugin
    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}