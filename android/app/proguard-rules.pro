# ─────────────────────────────────────────────────────────────────────────────
# CRITICAL: Keep generic type signatures so Gson's TypeToken can resolve them
# at runtime in release/R8 builds.
# Without this, zonedSchedule() crashes with:
#   IllegalArgumentException: Missing type parameter
# ─────────────────────────────────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep all Gson classes and their members
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep any class that extends TypeToken (anonymous or named)
-keep class * extends com.google.gson.reflect.TypeToken { *; }

# Keep SerializedName-annotated fields (used by Gson for serialization)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ─────────────────────────────────────────────────────────────────────────────
# flutter_local_notifications Android plugin
# Keep all models used for SharedPreferences serialization/deserialization
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep the RuntimeTypeAdapterFactory and all StyleInformation subtypes
-keep class com.dexterous.flutterlocalnotifications.RuntimeTypeAdapterFactory { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.styles.** { *; }

# Suppress warnings for optional Google Play Core classes used by Flutter
# deferred components feature — not needed for this app.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
