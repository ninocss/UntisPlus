import org.jetbrains.kotlin.gradle.dsl.JvmTarget

import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ninocss.untisplus"
    // androidx.core 1.19 requires API 37. This is deliberately independent
    // from targetSdk/minSdk, so existing runtime compatibility remains intact.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ninocss.untisplus"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Flutter's source-manifest launcher discovery does not inspect
        // activity aliases. Enable the real launcher for debug/profile runs;
        // release keeps the selectable icon aliases as the sole launcher.
        manifestPlaceholders["flutterToolLauncherEnabled"] = "true"
    }

    signingConfigs {
        create("release") {
            val targetFile = keystoreProperties.getProperty("storeFile") ?: "release-key.jks"
            storeFile = file(targetFile)
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            manifestPlaceholders["flutterToolLauncherEnabled"] = "false"
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    dependenciesInfo {
        // Disable Google dependency-metadata blob (flagged by IzzyOnDroid/F-Droid APK scanners)
        includeInApk = false
        includeInBundle = false
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

dependencies {
implementation("androidx.core:core-ktx:1.19.0")
      coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
