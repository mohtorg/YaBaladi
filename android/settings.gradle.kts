pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // ✅ [v5 — 2026-10-27] AGP 8.11.1 — الحد الأدنى المطلوب من Flutter الجديد
    id("com.android.application") version "8.11.1" apply false
    // [v4 — 2026-10-21] Kotlin 2.1.20 — حل نهائي لخطأ metadata
    //  → متوافق مع kotlin-stdlib-2.1.20 و annotation-jvm-1.10.0
    //  → متوافق مع AGP 8.11.1 و Flutter 3.47
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
}

include(":app")