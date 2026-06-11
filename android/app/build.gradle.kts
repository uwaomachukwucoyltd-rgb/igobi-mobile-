import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Cloud Messaging (com.google.gms.google-services) is applied
    // conditionally below — only when google-services.json is present — so the
    // app still builds locally before `flutterfire configure` has been run.
}

// Apply the Google Services plugin only when its config file exists. Without
// this guard the plugin hard-fails the build when google-services.json is
// absent, which blocks every local/CI build until Firebase is configured.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn(
        "google-services.json not found in android/app — Firebase (FCM, Google " +
        "sign-in) is DISABLED for this build. Run `flutterfire configure` to enable.",
    )
}

// Load signing config from android/key.properties (gitignored) if present.
// Generate the keystore with:
//   keytool -genkey -v -keystore ~/igobi-upload.jks -keyalg RSA -keysize 2048 \
//     -validity 10000 -alias upload
// Then create android/key.properties:
//   storeFile=/Users/you/igobi-upload.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    // Namespace is the *internal* Kotlin package — matches the MainActivity
    // file path. applicationId below is what the stores see.
    namespace = "app.igobi.customer"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.igobi.customer"
        minSdk = flutter.minSdkVersion           // Android 6.0 — required by flutter_secure_storage
        targetSdk = 35        // Play Console policy as of 2025
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // If key.properties is present, sign with the upload key. Otherwise
            // fall back to the debug keystore so `flutter run --release` works
            // locally; CI / Play uploads must have key.properties.
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8 re-enabled. We use the MODULAR Play Core
            // (com.google.android.play:feature-delivery 2.1.0, declared below
            // in dependencies). It covers the splitinstall.* classes Flutter's
            // PlayStoreDeferredComponentManager references but DOES NOT
            // include the deprecated com.google.android.play.core.tasks.*
            // package. proguard-rules.pro tells R8 not to error on those
            // missing classes — we don't use deferred components so the code
            // path is dead.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Keep debug builds installable alongside release on the same device.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Modular Play Core. Covers the splitinstall.* classes referenced by
    // Flutter's PlayStoreDeferredComponentManager without dragging in the
    // monolithic com.google.android.play:core which clashes with core-common
    // (pulled transitively by google_sign_in_android). The missing
    // com.google.android.play.core.tasks.* classes are dontwarn'd in
    // proguard-rules.pro — they're only reached if we ever turn on deferred
    // components, which we don't.
    implementation("com.google.android.play:feature-delivery:2.1.0")
}

