# google_mlkit_text_recognition references the optional per-script
# recognizer classes (Chinese/Devanagari/Japanese/Korean) generically from
# its `TextRecognizer.initialize()` method, but this app only uses the
# default Latin-script recognizer and never pulls in those optional
# per-script dependencies. R8 can't resolve them and fails release builds
# without these directives, even though the missing classes are never
# actually reached at runtime.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit's face detection/text recognition/barcode scanning plugins reach
# their model-loading and options classes via reflection. Without explicit
# keep rules, R8's minification in release builds can rename/strip pieces
# of these classes - the app still compiles and even runs (nothing crashes),
# but on-device model initialization silently never completes, which is why
# the live scanner can get stuck on "Preparing scanner..." in a release
# build while working fine in debug (unminified).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_face.** { *; }
-dontwarn com.google.mlkit.**
