# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Socket.IO
-keep class io.socket.** { *; }
-keep class okhttp3.** { *; }
-dontwarn io.socket.**
-dontwarn okhttp3.**

# Gson (used by some Firebase/Socket.IO libs)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# geolocator / geocoding
-keep class com.baseflow.geolocator.** { *; }

# SQLite
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }

# Flutter local notifications
-keep class com.dexterous.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Keep model classes intact (prevent R8 from renaming JSON fields)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
