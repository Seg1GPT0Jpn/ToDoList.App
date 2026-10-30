import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// アップロード鍵は android/key.properties（Git に入れない）から読む。
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.kazu.tsuzuri_light"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications（学習リマインダー）に必要
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kazu.tsuzuri_light"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // in_app_purchase 3.3.x の Android サポート要件に合わせる
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // key.properties があればアップロード鍵で署名し、無ければ debug 鍵（ローカル確認用）。
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// つづりクエストの部品から入ってくるファイルのうち、APK に入れないもの（Flutter が同梱ファイルを写すときに外す）
// - Light では使わない：BGM・効果音、見出しの明朝体、本文フォントのつづりクエスト側の写し（Light は TsuzuriLightSans.ttf）
// - 開いたときにネットから読んで端末に残す（lib/remote_assets_io.dart）：資料（materials）・予想問題（mock_exams）。約36MB
tasks.withType<Copy>().configureEach {
    if (name.startsWith("copyFlutterAssets")) {
        exclude(
            "**/packages/rpg_game_app/assets/audio/**",
            "**/packages/rpg_game_app/assets/materials/**",
            "**/packages/rpg_game_app/assets/mock_exams/**",
            "**/packages/rpg_game_app/assets/fonts/NotoSerifJP-Bold.ttf",
            "**/packages/rpg_game_app/assets/fonts/OFL-NotoSerifJP.txt",
            "**/packages/rpg_game_app/assets/fonts/NotoSansJP-Regular.ttf",
        )
    }
}
