# File: android/app/proguard-rules.pro
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
# Supabase & Encrypt
-keep class com.supabase.** { *; }
-dontwarn com.google.errorprone.annotations.**

# --- TAMBAHAN UNTUK MEMPERBAIKI ERROR R8 ---
# Beritahu R8 untuk mengabaikan warning dari Google Play Core
# karena kita tidak pakai fitur Dynamic Features / Deferred Components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# Opsional: Jika masih bandel, tambahkan ini
-keep class com.google.android.play.core.** { *; }