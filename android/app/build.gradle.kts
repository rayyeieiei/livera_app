plugins {
    id("com.android.application")
    // 🔥 BIAR GAK ERROR: Kita matiin dulu pengecekan Firebase Google Services pas ganti ID jir!
    // id("com.google.gms.google-services") 
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.livera_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // KTP baru lu aman nangkring di sini jir
        applicationId = "com.example.livera_app"
        
        minSdkVersion(flutter.minSdkVersion)
        targetSdkVersion(flutter.targetSdkVersion)
        
        // Pake gaya Kotlin yang bener biar gak kena Unexpected Tokens lagi wkwk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.firebase:firebase-analytics-ktx:21.3.0")
    implementation("com.google.firebase:firebase-auth-ktx:22.1.0")
    implementation("com.google.android.gms:play-services-auth:21.0.0")
}

flutter {
    source = "../.."
}