import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload-key credentials live only in an untracked android/key.properties file.
// Absence must never fall back to the debug keystore.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun releaseSigningValue(name: String): String {
    val value = keystoreProperties.getProperty(name)?.trim().orEmpty()
    if (value.isEmpty() || value.startsWith("REPLACE_WITH_")) {
        throw GradleException(
            "android/key.properties is missing a real '$name'. " +
                "Copy android/key.properties.example and point it at your Play upload key. " +
                "FitFlow will not sign a release with the debug key.",
        )
    }
    return value
}

android {
    namespace = "com.fitflow.fitflow"
    // Explicit Play baseline. Do not inherit Flutter's moving defaults.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (java.time on older APIs).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseSigningValue("keyAlias")
                keyPassword = releaseSigningValue("keyPassword")
                storePassword = releaseSigningValue("storePassword")
                storeFile = file(releaseSigningValue("storeFile"))
            }
        }
    }

    defaultConfig {
        // Candidate for the first Play upload. Confirm and register this exact
        // value in Play Console before upload. Do not rename it after release.
        applicationId = "com.fitflow.fitflow"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // No debug-sign fallback. Without key.properties the release task
            // fails below; debug builds are unaffected.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

val releaseSigningMessage =
    "Release signing is not configured. Copy android/key.properties.example to " +
        "android/key.properties and point it at your Play upload keystore. " +
        "FitFlow will not sign a release build with the debug key."

tasks.configureEach {
    val isReleasePackage = name == "signReleaseBundle" ||
        ((name.startsWith("assemble") ||
            name.startsWith("bundle") ||
            name.startsWith("package") ||
            name.startsWith("sign")) &&
            name.endsWith("Release"))
    if (isReleasePackage) {
        doFirst {
            if (!hasReleaseSigning) {
                throw GradleException(releaseSigningMessage)
            }
            val store = signingConfigs.getByName("release").storeFile
            if (store == null || !store.exists()) {
                throw GradleException(
                    "Upload keystore not found at '${store?.path}'. " +
                        "Check storeFile in android/key.properties. " +
                        "FitFlow will not sign a release build with the debug key.",
                )
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
