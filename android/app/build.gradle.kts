plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.egypt.yabaladi_rebuild"
    compileSdk = flutter.compileSdkVersion
    
    // ✅ [v4 — 2026-11-02] تم التحديث لحل خطأ البناء الخاص بـ jni و google_maps
    ndkVersion = "28.2.13676358"

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

// ✅ الحل الجذري: تعطيل مهمة ArtProfile لحل خطأ compileReleaseArtProfile على FlutterLab
tasks.whenTaskAdded {
    if (name.contains("ArtProfile")) {
        enabled = false
    }
}