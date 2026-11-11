plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sparkleen.sparkleen_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sparkleen.sparkleen_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("preview") {
            dimension = "environment"
            applicationIdSuffix = ".preview"
            manifestPlaceholders["appLabel"] = "Sparkleen Preview"
            manifestPlaceholders["allowCleartext"] = "true"
        }
        create("production") {
            dimension = "environment"
            manifestPlaceholders["appLabel"] = "Sparkleen"
            manifestPlaceholders["allowCleartext"] = "false"
        }
    }

    buildTypes {
        release {
            // Internal previews are debug-signed; store releases require owner-managed signing.
            // Production distribution needs an owner-managed release signing key.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Internal preview signing must never silently become a production release.
if (gradle.startParameter.taskNames.any { it.contains("Production", ignoreCase = true) && it.contains("Release", ignoreCase = true) }) {
    throw GradleException("Configure owner-managed production signing before distributing a production build.")
}

dependencies {
    implementation("androidx.biometric:biometric:1.1.0")
}
