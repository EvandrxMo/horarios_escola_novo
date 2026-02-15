plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.horarios_escola_novo"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.horarios_escola_novo"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lint {
        warning += "InvalidPackage"
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring atualizado para compatibilidade com plugins recentes
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Core Android libraries
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.activity:activity-ktx:1.12.2")
    implementation("androidx.activity:activity:1.12.2")

    // Adicione outros plugins nativos aqui se necessário
}
