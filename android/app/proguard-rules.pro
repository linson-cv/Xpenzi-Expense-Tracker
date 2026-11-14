# Flutter embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# App widgets & main activity
-keep class com.navlinlabs.xpenzi.** { *; }

# Google Play Core / In-App Review
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Gson / reflection used by flutter_local_notifications & plugins
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.dexterous.** { *; }
