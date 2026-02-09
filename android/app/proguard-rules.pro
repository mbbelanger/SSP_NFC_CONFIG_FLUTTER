# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# NFC Manager plugin (nfc_manager 4.x uses dev.flutter.plugins.nfcmanager)
-keep class dev.flutter.plugins.nfcmanager.** { *; }

# Keep Android NFC classes used by the plugin
-keep class android.nfc.** { *; }
-keep class android.nfc.tech.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Google Play Core (deferred components) - not used but referenced by Flutter
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
