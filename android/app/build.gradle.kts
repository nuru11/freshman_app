import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadKeystoreProperties(fileName: String): Properties {
    val properties = Properties()
    val propertiesFile = rootProject.file(fileName)
    if (propertiesFile.exists()) {
        properties.load(FileInputStream(propertiesFile))
    }
    return properties
}

val freshmanKeystoreProperties = loadKeystoreProperties("key.properties")

android {
    namespace = "com.vector_academy.app"
    compileSdk = flutter.targetSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // fvp and flutter_pdfview (pdfium) both ship libc++_shared.so.
    packaging {
        jniLibs {
            pickFirsts += "lib/**/libc++_shared.so"
        }
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (freshmanKeystoreProperties.isNotEmpty()) {
            create("freshmanRelease") {
                keyAlias = freshmanKeystoreProperties["keyAlias"] as String
                keyPassword = freshmanKeystoreProperties["keyPassword"] as String
                storeFile = freshmanKeystoreProperties["storeFile"]?.let { file(it) }
                storePassword = freshmanKeystoreProperties["storePassword"] as String
            }
        }
    }

    flavorDimensions += "app"
    productFlavors {
        create("freshman") {
            dimension = "app"
            applicationId = "com.freshmantricks.app"
            resValue("string", "app_name", "Freshman Tricks")
        }
        create("vector_academy") {
            dimension = "app"
            applicationId = "com.vector_academy.app"
            resValue("string", "app_name", "Entrance Tricks")
        }
        create("exitexam") {
            dimension = "app"
            applicationId = "com.ethioexitexam.app"
            resValue("string", "app_name", "Ethio Exit Exam")
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (freshmanKeystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("freshmanRelease")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
