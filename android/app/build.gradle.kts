import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val isDev = project.hasProperty("dev")

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties =
    Properties().apply {
        if (keyPropertiesFile.isFile) keyPropertiesFile.inputStream().use { load(it) }
    }

// Never fall back to the debug key: a release signed with one PC's debug key
// cannot update one signed with the other's, and the phone loses its data.
val releaseSigningProblem: String? =
    if (isDev) {
        null
    } else if (!keyPropertiesFile.isFile) {
        "${keyPropertiesFile.path} does not exist"
    } else {
        val missing =
            listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
                .filter { keyProperties.getProperty(it).isNullOrBlank() }
        val store = keyProperties.getProperty("storeFile")?.let(::File)
        val repo = rootProject.projectDir.parentFile.canonicalFile
        when {
            missing.isNotEmpty() -> "key.properties lacks ${missing.joinToString()}"
            !store!!.isAbsolute -> "storeFile must be an absolute path outside the repository"
            store.canonicalFile.startsWith(repo) -> "storeFile must be outside the repository ($repo)"
            !store.isFile -> "storeFile $store does not exist"
            else -> null
        }
    }

android {
    namespace = "dev.aritzmmartinez.quoin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.aritzmmartinez.quoin"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Quoin"
    }

    signingConfigs {
        if (!isDev && releaseSigningProblem == null) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    // Quoin dev (`.dev`) is a second install beside the real one, with its
    // own data and pairings. Debug and profile are signed with each PC's
    // debug key, so they always build Quoin dev: on the real package Android
    // would refuse the update and Flutter would uninstall it, data included.
    // `-Pdev` (`--android-project-arg=dev=true`) makes a release Quoin dev.
    buildTypes {
        configureEach {
            if (name != "release" || isDev) {
                applicationIdSuffix = ".dev"
                manifestPlaceholders["appLabel"] = "Quoin dev"
            }
        }
        release {
            signingConfig =
                if (isDev) {
                    signingConfigs.getByName("debug")
                } else {
                    signingConfigs.findByName("release")
                }
        }
    }
}

// Checked when a release task is about to run, not when configuring, so
// debug builds and CI need no key.
gradle.taskGraph.whenReady {
    val problem = releaseSigningProblem ?: return@whenReady
    if (allTasks.any { it.project == project && it.name.contains("Release") }) {
        throw GradleException(
            "The real Quoin release needs its own upload key: $problem. " +
                "See docs/release.md (Signing). For a release of Quoin dev, " +
                "signed with the debug key, pass --android-project-arg=dev=true.",
        )
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
    // WindowInsetsControllerCompat, for the immersive navigation bar.
    implementation("androidx.core:core-ktx:1.17.0")
}
