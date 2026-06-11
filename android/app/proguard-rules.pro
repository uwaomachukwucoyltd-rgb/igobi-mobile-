# IGOBI Mobile — R8 / ProGuard rules.
# Combined with the default proguard-android-optimize.txt.

# Keep Flutter engine + plugin registry.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_secure_storage — Android Keystore-backed; keep crypto reflection paths.
-keep class androidx.security.crypto.** { *; }
-keepclassmembers class androidx.security.crypto.** { *; }

# Dio + okhttp may hit deprecated APIs via reflection; suppress warnings only,
# don't keep everything.
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# go_router uses reflection-free named routes; nothing extra needed.

# Sentry — keep the Java/native bridge and its event model so stack traces
# survive minification.
-keep class io.sentry.** { *; }
-keepclassmembers class io.sentry.** { *; }
-dontwarn io.sentry.**

# Firebase Cloud Messaging — keep RemoteMessage and the service that delivers
# pushes while the app is backgrounded. Firebase's own consumer rules cover
# most of this; these are belt-and-braces.
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keepclassmembers class com.google.firebase.messaging.RemoteMessage { *; }
-dontwarn com.google.firebase.**

# webview_flutter — Hybrid Composition uses platform views; keep the
# Android-side handler so JS bridge calls resolve.
-keep class io.flutter.plugins.webviewflutter.** { *; }
-dontwarn io.flutter.plugins.webviewflutter.**

# Dio — uses reflection for FormData; keep its multipart writer.
-keep class com.github.diodart.dio.** { *; }
-dontwarn dio.**

# Strip log noise from release builds — Logger.t / print already stripped by
# the Dart side in release, but if you add logging packages later, this is
# where they hook in.
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Play Core deferred-components. We use the modular feature-delivery dep
# (declared in app/build.gradle.kts) which covers splitinstall.* but NOT the
# deprecated tasks.* package. The code paths referencing those classes are
# only reached when the app actually uses deferred components — which IGOBI
# does not. -dontwarn lets R8 finish without erroring on missing references.
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.listener.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep names of Riverpod providers and notifiers so stack traces in Sentry
# stay legible — minification shortens them otherwise.
-keepclassmembers class * extends com.example.flutter_riverpod.** { *; }
