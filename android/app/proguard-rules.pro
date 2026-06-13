# Gson rules to preserve generic signatures for TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Keep the TypeToken class and its subclasses
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * extends com.google.gson.reflect.TypeToken

# Keep classes used by flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# General Gson rules
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
