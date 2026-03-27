import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.dnggr.textify"
    compileSdk = 36          // Change from 34 to 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // This removes the "deprecated" warning
        freeCompilerArgs += listOf("-Xjsr305=strict")
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            // Use the .srcDir() function instead of +=
            java.srcDir("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.dnggr.textify"
        minSdk = flutter.minSdkVersion
        targetSdk = 36       // Change from 34 to 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            // Using debug signing for now so it runs on your phone easily
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-mlkit-text-recognition:19.0.0")
}
