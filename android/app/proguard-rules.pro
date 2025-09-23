# Keep Rhino classes used by NewPipeExtractor
-keep class org.mozilla.javascript.** { *; }
-dontwarn org.mozilla.javascript.**

# Android does not provide java.beans or javax.script; suppress warnings
-dontwarn java.beans.**
-dontwarn javax.script.**

# Optional: be conservative about keeping reflections
-keepattributes *Annotation*,InnerClasses,EnclosingMethod,Signature
