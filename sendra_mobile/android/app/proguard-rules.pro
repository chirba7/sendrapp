# Règles Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Désactiver les warnings pour les classes Play Core manquantes
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.app.FlutterPlayStoreSplitApplication

# Garder les classes de remplacement Play
-keep class com.google.android.play.core.common.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Règles pour le plugin Firebase (si vous l'utilisez)
-keep class com.google.firebase.** { *; }

# Garder les classes JNI
-keepclasseswithmembers class * {
    native <methods>;
}

# Garder les noms d'attributs pour les erreurs de sérialisation JSON
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Garder les composants personnalisés du Flutter
-keep class com.yourpackage.** { *; }

# Règles spécifiques pour votre application
-keep class net.appdevs.sendraPRO.** { *; }

# Règles pour AndroidX et API 35
-keep class androidx.core.** { *; }
-keep class androidx.activity.** { *; }
-keep class androidx.fragment.** { *; }
-keep class androidx.appcompat.** { *; }
-keep class androidx.lifecycle.** { *; }

# Règles pour les bibliothèques tierces
-dontwarn org.bouncycastle.jsse.BCSSLParameters
-dontwarn org.bouncycastle.jsse.BCSSLSocket
-dontwarn org.bouncycastle.jsse.provider.BouncyCastleJsseProvider
-dontwarn org.conscrypt.Conscrypt$Version
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.ConscryptHostnameVerifier
-dontwarn org.openjsse.javax.net.ssl.SSLParameters
-dontwarn org.openjsse.javax.net.ssl.SSLSocket
-dontwarn org.openjsse.net.ssl.OpenJSSE

# Garder R8 full mode
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,SourceFile,LineNumberTable,*Annotation*,EnclosingMethod

# Garder les informations de débogage
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Empêcher la duplication de classes dans les différents packages
-optimizations !code/simplification/cast

# Règles spécifiques pour corriger les erreurs R8
-keep class * extends java.lang.Exception
-keep class * extends java.lang.RuntimeException

# Règles pour éviter les erreurs de liaison des ressources Android
-keep class **.R
-keep class **.R$* { *; }

# Règles pour Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Règles pour Material Design
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**