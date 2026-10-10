# Flutter-specific ProGuard rules
-dontwarn io.flutter.embedding.**

# Keep Flutter engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep speech_to_text plugin
-keep class com.csdcorp.speech_to_text.** { *; }

# Keep flutter_tts plugin
-keep class com.tundralabs.fluttertts.** { *; }

# Keep url_launcher plugin
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep flutter_map plugin
-keep class com.flutter_map.** { *; }
