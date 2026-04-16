pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localPropertiesFile = file("local.properties")

            if (localPropertiesFile.exists()) {
                localPropertiesFile.inputStream().use { properties.load(it) }
            }

            val flutterSdkPath =
                properties.getProperty("flutter.sdk")
                    ?: System.getenv("FLUTTER_ROOT")
                    ?: System.getenv("FLUTTER_HOME")

            require(flutterSdkPath != null) {
                "flutter.sdk not set. Define it in android/local.properties or set FLUTTER_ROOT/FLUTTER_HOME."
            }
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
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
