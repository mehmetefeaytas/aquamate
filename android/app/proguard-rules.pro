# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# flutter_local_notifications: Gson ile serileştirilen model sınıfları
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.gson.**

# sqflite / sqlite
-keep class com.tekartik.sqflite.** { *; }

# audioplayers / video_player
-keep class xyz.luan.audioplayers.** { *; }
-keep class io.flutter.plugins.videoplayer.** { *; }

# timezone verisi yansıma ile yükleniyor
-keep class org.threeten.bp.** { *; }
-dontwarn org.threeten.bp.**

# Play Core (Flutter deferred components) - kullanılmıyor
-dontwarn com.google.android.play.core.**
