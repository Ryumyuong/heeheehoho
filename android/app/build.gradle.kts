import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Firebase: android/app/google-services.json 을 읽어 앱에 주입한다.
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리즈 서명 키는 저장소에 넣지 않는다.
// android/key.properties 에 아래 4개 값을 두면 릴리즈 빌드가 그 키로 서명된다.
//   storeFile=C:/경로/heeheehoho-release.jks
//   storePassword=...
//   keyAlias=heeheehoho
//   keyPassword=...
// 파일이 없으면(예: CI 없이 로컬 디버그) 디버그 키로 폴백한다.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.heeheehoho.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // 플레이스토어 등록 후에는 절대 바꿀 수 없는 값.
        applicationId = "com.heeheehoho.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // pubspec.yaml 의 version(1.0.0+1)에서 온다. 스토어에 올릴 때마다 +1 을 올려야 한다.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // 서명 키가 아직 없을 때만. 이 상태로 만든 파일은 스토어에 올릴 수 없다.
                signingConfigs.getByName("debug")
            }
            // R8 난독화는 켜지 않는다(Flutter 기본값). 켰더니 R8이 컴파일에 실패했고,
            // 스토어 등록에 필수도 아니다. 필요해지면 proguard 규칙부터 정리할 것.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
