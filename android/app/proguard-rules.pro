# ProGuard rules for NaviQ

# Keep Flutter wrapper and plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Background Service
-keep class id.flutter.flutter_background_service.** { *; }

# Shared Preferences
-keep class com.russhwolf.settings.** { *; }

# Keep model classes from being obfuscated if they are used for JSON serialization
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Preserve line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable

# Flutter engine references Play Core split-install classes for deferred component support.
# This project does not use deferred components, so these classes are absent.
# R8 auto-generated these rules from missing_rules.txt — suppress the missing-class errors.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# RevenueCat / PurchasesHybridCommon
-keep class com.revenuecat.purchases.** { *; }
-keep class com.revenuecat.purchases.hybrid.common.** { *; }
-dontwarn com.revenuecat.purchases.**
