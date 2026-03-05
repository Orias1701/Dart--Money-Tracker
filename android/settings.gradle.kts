pluginManagement {
    val localPropertiesFile = file("local.properties")
    require(localPropertiesFile.exists()) { "local.properties not found" }
    val properties = java.util.Properties().apply {
        localPropertiesFile.inputStream().use { load(it) }
    }
    val flutterSdkPath = properties.getProperty("flutter.sdk")
    require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
    if (properties.getProperty("sdk.dir") == null) {
        val androidHome = System.getenv("ANDROID_HOME")
        if (androidHome != null) {
            properties.setProperty("sdk.dir", androidHome)
            localPropertiesFile.writer().use { properties.store(it, null) }
        } else {
            throw GradleException(
                "Android SDK location not found. Set ANDROID_HOME environment variable " +
                    "or add sdk.dir=<path> to android/local.properties"
            )
        }
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
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
