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

    // [v4 — 2026-11-19] توقيع release بمفتاح خاص من android/key.properties (غير مرفوع إلى Git).
    // دون الملف يعود البناء إلى مفتاح debug للتطوير فقط، ولن تقبله Play.
    signingConfigs {
        create("release") {
            val props = java.util.Properties()
            val f = rootProject.file("key.properties")
            if (f.exists()) {
                f.inputStream().use { props.load(it) }
                storeFile = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            val hasKey = rootProject.file("key.properties").exists()
            signingConfig = if (hasKey) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
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