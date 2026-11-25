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
    // [v6 — 2026-11-02] Kotlin 2.3.10 — مواءمة مع kotlin-stdlib-2.3.10 المفروضة من الاعتماديات
    //  → يعالج: Module was compiled with an incompatible version of Kotlin
    id("org.jetbrains.kotlin.android") version "2.3.10" apply false
    // [v7 — 2026-11-19] معالجة google-services.json (كانت غائبة فلم يُولَّد default_web_client_id)
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")