import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}


dependencies {
    // MaterialComponents themes (styles.xml) — required by flutter_stripe's PaymentSheet
    implementation("com.google.android.material:material:1.12.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Release signing: create android/key.properties (never commit it) with
//   storeFile=<path to .jks, relative to android/app>
//   storePassword=...
//   keyAlias=...
//   keyPassword=...
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.example.safarsync_mobileapp"
    // compileSdk 36 is required by current plugins (androidx.browser 1.9 etc.).
    // targetSdk stays at 35, which satisfies Google Play's target-API rule.
    // NDK pinned to the version installed on the build machine.
    compileSdk = 36
    ndkVersion = "30.0.16248370"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Play Store package name. Google Play rejects "com.example.*" ids.
        // NOTE: Google Sign-In's Android OAuth client must be registered for
        // this package name + the release signing SHA-1.
        applicationId = "com.safarsync.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // All traffic goes to Supabase Cloud over HTTPS — cleartext is never needed.
        manifestPlaceholders["usesCleartextTraffic"] = "false"
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("WARNING: android/key.properties not found — release APK is signed with the DEBUG key.")
                signingConfigs.getByName("debug")
            }
            // R8 code shrinking — removes unused classes and obfuscates
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // ABI splits disabled to avoid conflicts with NDK configuration
    // Flutter will handle architecture selection automatically
}

flutter {
    source = "../.."
}
